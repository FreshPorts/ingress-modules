#!/usr/bin/perl -w

use strict;
 
use DBI;

my $topic='';
my @TOPICS;
my $sql;
my $sth;
my @row;

# =================================
sub ReadFile($) {

   my $file = shift;
   my $content;

   open F,$file;

   $content = "";
   while(<F>){
      $content .= $_;
   }
 
   close F;

   return $content;
}

# =================================

sub SendMail($;$) {

  my $Bcc		= shift;
  my $IncludeFile	= shift;

  my $content = ReadFile($IncludeFile);

   open(SENDMAIL, "|/usr/sbin/sendmail -oi -t")
                    or die "Can't fork for sendmail: $!\n";

print SENDMAIL <<"EOF";
From: FreshPorts watch daemon <freshports-watch\@freshports.org>
To: freshports-watch\@freshports.org
Bcc: $Bcc
Subject: FreshPorts watch list notification

EOF


print SENDMAIL $content;

print SENDMAIL <<"EOF";
--

You are receiving this message as part of the service
you joined at http://forum.linz.govt.nz/
EOF

   
   close(SENDMAIL)     or warn "sendmail didn't close nicely";

}

sub CompileBccListForTopic($;$) {

   my $Topic_ID = shift;
   my $dbh = shift;
   my $sth;
   my $sql;
   my $Bcc;

   #
   # get a list of people subscribed to this topic
   #

   $sql = "select email \
           from subscribe, user \
           where subscribe.user_id = user.id \
           order by email";

   $sth = $dbh->prepare($sql);
   $sth->execute ||
           die "Could not execute SQL $sql ... maybe invalid?";

   while (@row=$sth->fetchrow_array) {
      print "now processing @row\n";
      $Bcc .= $row[0] . ",";
   }

   # we always send a message to the admin person.
   # this also means we don't have to remove any trailing commas 
   # from the above while loop

   $Bcc .= "dan.langille\@synergy.co.nz";

   return $Bcc;
}

sub SetWatchLastNoticeDate($;$) {

   my $Frequency = shift;
   my $dbh = shift;

   $sql = "update watch_notice \
              set last_sent              = NOW() \
            where watch_notice.frequency = '$Frequency'";

   $sth = $dbh->prepare($sql);

   $sth->execute ||
           die "Could not execute SQL $sql ... maybe invalid?";
}


my $dbh = DBI->connect('dbi:mysql:linz','linz','linz27');

#
# get a list of topics which are subscribed to
#
$sql = "select distinct(topic_id) from subscribe;";
$sth = $dbh->prepare($sql);
$sth->execute ||
         die "Could not execute SQL $sql ... maybe invalid?";

while (@row=$sth->fetchrow_array) {
   print "now processing @row\n";
   push @TOPICS, "$row[0]"
}

my $OutputFile = "/tmp/mailoutput.txt";
my @myrow;

#
# for each topic
#
foreach $topic (@TOPICS) {
   print "found $topic\n";

   $sql = "select subject, body, date_posted, time_posted, username, name  \
           from message, user \
          where message.author_id = user.id \
            and discussion_id = $topic \
          order by date_posted, time_posted";

   print "sql = $sql\n";

   $sth = $dbh->prepare($sql);
   $sth->execute ||
         die "Could not execute SQL $sql ... maybe invalid?";

   open FILE, ">$OutputFile"  || die "Could not open $OutputFile";
           
   my $count =0;
   if (*FILE) {
      print "file opened\n";
      while (@myrow = $sth->fetchrow_array) {
         $count++;
         print "processing message $count\n";
         print FILE "From:    $myrow[5]\n";
         print FILE "Subject: $myrow[0]\n";
         print FILE "Date:    $myrow[2] $myrow[3]\n\n";
         print FILE "$myrow[1]\n\n\n";
      }
      close FILE;
   } else {
      print "file open failed\n";
   }

   if ($count > 0) {
      #
      # get the list of people for this topic
      #

      my $Bcc = CompileBccListForTopic($topic, $dbh);
      print "mail will be sent to $Bcc\n";
      SendMail($Bcc, $OutputFile);
   } else {
      print "no messages found for topic $topic\n";
   }

}

$dbh->disconnect();


