#!/usr/bin/perl

#
# FreshPorts - takes log details and creates daily summaries
# written by Dan Langille
# copyright 2000 DVL Software
#

use DBI;
use strict;

use lib '/usr/local/etc/freshports/updates';
use ports;

my $NotifyByMail = "root";
my $PathToUse    = "/usr/local/etc/freshports.changes/archives";  # must NOT include a trailing /
my @myrow;

if (($#ARGV+1) == 1) {
   print "there is 1 arguments\n";

   my $StartDate = $ARGV[0];


   my $dbh = DBI->connect('dbi:mysql:freshports', 'freshports', 'marlboro');
   if (!$dbh) {
      # email the main man
      open  MAIL, "|mail -s 'freshports error' $NotifyByMail";
      print MAIL "The daily summary creator could not connect to the database\n";
      close MAIL;

      exit;
   }

   CreateDailySummary($StartDate, $dbh);

   $dbh->disconnect();
} else {
   print "please specify a start date\n";
}

