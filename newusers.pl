#!/usr/bin/perl
#
# $Id: newusers.pl,v 1.3.2.7 2004-11-27 13:54:07 dan Exp $
#
# Copyright (c) 2001-2003 DVL Software
#

use strict;
use DBI;

use database;
use commit_log_ports_ignore;
use system_status;

sub SendNotice($;$) {
   my $StartDate = shift;
   my $msgbody   = shift;

	my $From         = 'FreshPorts Daemon <FreshPorts@FreshPorts.org>';
	my $To           = 'Dan Langille <dan@langille.org>';
	my $CC           = '';
	my $Subject      = "FreshPorts -- new users  - $StartDate";
	my $ExtraHeaders = 'X-FreshPorts-NewUsers: ' . $StartDate;

	my $Body = "The following users were added yesterday:

$msgbody --

";
	FreshPorts::email::SendMail($From, $To, $CC, $Subject, $Body, $ExtraHeaders);
}

#
# see if the system is online.
# If not, exit.
#
my $SystemStatus = FreshPorts::SystemStatus->new();
if (!$SystemStatus->Online()) {
	exit 0;
}

if (($#ARGV+1) == 2) {
   print "there are 2 arguments\n";

   my $StartDate = $ARGV[0];
   my $EndDate   = $ARGV[1];

   my $dbh = FreshPorts::Database::GetDBHandle();
   if (!$dbh) {
      print " connect failed\n";
   }
   my $sql = "select id, name, email, firstlogin \
              from users \
              where date_trunc('day', firstlogin) = '$StartDate'
              order by id";

   print "sql is $sql\n";

   my $sth = $dbh->prepare($sql);
   $sth->execute ||
           die "Could not execute SQL $sql ... maybe invalid?";

   my $msgbody = '';

   while (my @row=$sth->fetchrow_array) {
      $msgbody .= $row[0] . " : " . $row[1] . " : " . $row[2] . " : " . $row[3] . "\n";
   }

   print "msgbody = \n" . $msgbody;
   if ($msgbody != '') {
#      SendNotice($StartDate, $msgbody);
   }

   $dbh->disconnect();
} else {
   print "please specify a start date and an end date\n";
}
