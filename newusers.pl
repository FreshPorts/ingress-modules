#!/usr/bin/perl
#
# $Id: newusers.pl,v 1.3.2.3 2002-12-12 04:59:12 dan Exp $
#
# Copyright (c) 2001 DVL Software
#

use strict;
use DBI;

use lib "$ENV{HOME}/scripts";
use database;

sub SendNotice($;$) {
   my $StartDate = shift;
   my $msgbody   = shift;

	my $Body = "The following users were added yesterday:

$msgbody --

";
	FreshPorts::email::SendMail('FreshPorts Daemon <FreshPorts@FreshPorts.org>', 'Dan Langille <dan@langille.org>', "FreshPorts -- new users  - $StartDate", $Body, 'X-FreshPorts-NewUsers: ' . $StartDate);
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
