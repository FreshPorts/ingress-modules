#!/usr/bin/perl -w

use strict;

use lib '/usr/local/etc/freshports/updates';
use ports;
 
use DBI;

my $dirname='';
my @USERS;
my $sql;
my $sth;
my @row;
my $Bcc;

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

   $sql = "select distinct(users.id), users.email \
             from change_log, change_log_port, watch_notice, watch_port, watch, users \
            where change_log.date_added         >= watch_notice.last_sent \
              and change_log.id                 = change_log_port.change_log_id \
              and watch_notice.frequency        = '$Frequency' \
              and watch_port.port_id            = change_log_port.port_id \
              and watch_port.watch_id           = watch.id \
              and users.id                      = watch.owner_user_id \
              and users.watchnotifyfrequency    = '$Frequency' \
              and length(users.email)           > 0 \
              and users.emailbouncecount        = 0 \
            order by users.email";

   print "sql is $sql\n";

   $sth = $dbh->prepare($sql);
   $sth->execute ||
           die "Could not execute SQL $sql ... maybe invalid?";

   while (@row=$sth->fetchrow_array) {
      print "now processing @row\n";
      push @USERS, "$row[1]"
   }

   foreach $dirname (@USERS) {
      $Bcc .= $dirname . ',';
      print "found $dirname\n";
   }

   $Bcc .= 'freshports-watch@freshports.org';

   print "and the Bcc list is $Bcc\n";

   return $Bcc
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

print "start  " . `date "+%Y-%m-%d %H:%M:%S"`;

if (($#ARGV+1) == 1) {
   print "there is 1 argument\n";

   my $Frequency = $ARGV[0];

   if ($Frequency eq 'D' || $Frequency eq 'W' || $Frequency eq 'F' || $Frequency eq 'M') {

      #my $dbh = DBI->connect('dbi:mysql:freshportstest','root','xyzzy');
      my $dbh = DBI->connect('dbi:mysql:freshports','root','xyzzy');

      $Bcc = CompileWatchNotifyList($Frequency, $dbh);

      SetWatchLastNoticeDate($Frequency, $dbh);

      $dbh->disconnect();

      SendWatchNotice($Bcc);

      print "message sent to users\n";
   } else {
      print "$Frequency as mail out frequency is not known to me.\n";
   }
} else {
  print "please specify a frequency such as D, W, F, M\n";
}

print "start " . `date "+%Y-%m-%d %H:%M:%S"`;
