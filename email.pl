#!/usr/bin/perl -w

use strict;
use DBI;

use Text::Wrap;

use lib '/home/freshports.org/scripts/updates';
use ports;

use lib '/home/freshports.org/scripts';
use freshports_database;

my $dirname='';
my @USERS;
my $sql;
my $sth;
my @row;
my $Bcc;

my $FormatDate	= "%W, %b %e";
my $FormatTime	= "%H:%i";

sub CompileWatchNotifyList($;$) {

   my $Frequency = shift;
   my $dbh = shift;
   my $sth;
   my $sql;

   #
   # get a list of ports to update
   #
   # the following line restricts mailouts to just me.
   #               and users.id                      = 2

   $sql = "select users.id, \
                  users.email, \
                  categories.name as category, \
                  ports.name as port, \
                  date_format(change_log.commit_date, '$FormatDate $FormatTime'), \
                  change_log.update_description  \
             from change_log, change_log_port, watch_notice, watch_port, watch, users, ports, categories \
            where change_log.date_added         >= watch_notice.last_sent \
              and change_log.id                 = change_log_port.change_log_id \
              and watch_notice.frequency        = '$Frequency' \
              and watch_port.port_id            = change_log_port.port_id \
              and watch_port.watch_id           = watch.id \
              and users.id                      = watch.owner_user_id \
              and users.watchnotifyfrequency    = '$Frequency' \
              and length(users.email)           > 0 \
              and users.emailbouncecount        = 0 \
              and ports.id                      = change_log_port.port_id
              and ports.primary_category_id     = categories.id
            order by users.id, categories.name, ports.name, change_log.commit_date";

   print "sql is $sql\n";

   $sth = $dbh->prepare($sql);
   $sth->execute ||
           die "Could not execute SQL $sql ... maybe invalid?";

   my $LastID;
   my $Body;
   my $To;
   my $FrequencyLong;

   undef($LastID);

   if ($Frequency eq 'D') { $FrequencyLong = 'daily'};
   if ($Frequency eq 'W') { $FrequencyLong = 'weekly'};
   if ($Frequency eq 'F') { $FrequencyLong = 'fortnightly'};
   if ($Frequency eq 'M') { $FrequencyLong = 'monthly'};


   while (@row=$sth->fetchrow_array) {
      print "now processing @row\n";

      # make sure that the first time through, we have a value
      if (!defined($LastID)) {
         $LastID = $row[0];
         $To     = $row[1];
      }

#      print "LastID = '$LastID' and id = '$row[0]'\n";
      if ($LastID != $row[0]) {
         SendWatchNoticePersonal($To, $FrequencyLong, $Body);

         $Body   = '';
         $To     = $row[1];
         $LastID = $row[0];
      }

      # get the category and port
      $Body .= $row[2] . '/' . $row[3] . "\n";

      # and wrap the description of the change.
      $Body .= wrap("     ", "     ", $row[5]) . "\n";
      $Body .=      "     $row[4]\n\n";

   }

   # if we got at least one, send out email
   if (defined($LastID)) {
      SendWatchNoticePersonal($To, $FrequencyLong, $Body);
   }
}

sub SetWatchLastNoticeDate($;$;$) {

   my $Frequency = shift;
   my $dbh       = shift;
   my $time      = shift;

   $sql = "update watch_notice \
              set last_sent              = '$time' \
            where watch_notice.frequency = '$Frequency'";

print 'SQL = ' . $sql;

   $sth = $dbh->prepare($sql);

   $sth->execute ||
           die "Could not execute SQL $sql ... maybe invalid?";
}

#
# use current time as cutoff for next time we do this
#
my $time = `date "+%Y-%m-%d %H:%M:%S"`;

#
# if we don't chomp, we'll have a \n in the string
# which SQL won't like
#
chomp $time;


print "start  $time\n";

if (($#ARGV+1) == 1) {
   print "there is 1 argument\n";

   my $Frequency = $ARGV[0];

   if ($Frequency eq 'D' || $Frequency eq 'W' || $Frequency eq 'F' || $Frequency eq 'M') {

      my $dbh = freshports_connect();

      CompileWatchNotifyList($Frequency, $dbh);

      SetWatchLastNoticeDate($Frequency, $dbh, $time);

      $dbh->disconnect();

      print "message sent to users\n";
   } else {
      print "$Frequency as mail out frequency is not known to me.\n";
   }
} else {
  print "please specify a frequency such as D, W, F, M\n";
}

print "start " . `date "+%Y-%m-%d %H:%M:%S"`;
