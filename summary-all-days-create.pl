#!/usr/bin/perl

#
# FreshPorts - takes log details and creates daily summaries
# written by Dan Langille
# copyright 2000 DVL Software
#

use DBI;
use strict;

my $NotifyByMail = "root";
my $PathToUse    = "/usr/local/etc/freshports.changes/archives";  # must NOT include a trailing /
my @myrow;

my $dbh = DBI->connect('dbi:mysql:freshportschange','updater','xyzzy');
if (!$dbh) {
   # email the main man
   open  MAIL, "|mail -s 'freshports error' $NotifyByMail";
   print MAIL "The updater could not connect to the databse\n";
   close MAIL;

   exit;
}


my $sql = "select ports.id, ports.name, ports.version, " .
          " date_format(change_log.commit_date, '%Y-%m-%d') as commit_date ".
          "from ports, change_log_port, change_log ".
          "where ports.id                      = change_log_port.port_id ". 
          "  and change_log_port.change_log_id = change_log.id ". 
          "order by change_log.commit_date desc";

my $sth = $dbh->prepare($sql);

$sth->execute ||
     die "Could not execute SQL statement ... maybe invalid?";

my $PrevDate;
my $OutputFile;

while (@myrow = $sth->fetchrow_array) {
   if ($PrevDate ne $myrow[3]) {
      print "* * * $myrow[3] * * *\n";
      $PrevDate = $myrow[3];
      # open a new file in $PathToUse/YYYY/MM/DD.inc
      if ($OutputFile) {
         print "closing old file first\n";
         close FILE;
      }

      umask(2);
      # create the output file name gradually, ensuring the directories exist

      $OutputFile = $PathToUse . "/" .
                     substr($myrow[3], 0, 4);

      if (-d $OutputFile) {
         print "'$OutputFile' exists\n";
      } else {
         print "'$OutputFile' does not exist\n";   
         print "   trying to mkdir '$OutputFile'\n";
         if (mkdir $OutputFile, 0775) {
         } else {
            die "Could not create directory $OutputFile";
         }
      }

      $OutputFile .= "/" . substr($myrow[3], 5, 2);
      if (-d $OutputFile) {
         print "'$OutputFile' exists\n";
      } else {
         print "   trying to mkdir '$OutputFile'\n";
         if (mkdir $OutputFile, 0775) { 
         } else {
            die "Could not create directory $OutputFile";
         }
      }

      $OutputFile .= "/" .  substr($myrow[3], 8, 2) . ".inc";
      print "   trying to open '$OutputFile'\n";
      open FILE, ">$OutputFile"  || die "Could not open $OutputFile";
   }

   print FILE '<a href="port-description.php3?port=' . $myrow[0] . '"><font size="-1">' . $myrow[1] . ' ' . $myrow[2] . "</font></a><br>\n";
}

if ($OutputFile) {
   close FILE;
}

$dbh->disconnect();

