#!/usr/bin/perl
#
# $Id: newusers.pl,v 1.3.2.5 2003-07-31 17:53:39 dan Exp $
#
# Copyright (c) 2001-2003 DVL Software
#

use strict;
use DBI;

use lib "$ENV{HOME}/scripts";
use database;

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
