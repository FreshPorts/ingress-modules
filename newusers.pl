#!/usr/bin/perl
#
# $Id: newusers.pl,v 1.3 2002-01-06 07:17:04 dan Exp $
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

   open(SENDMAIL, "|/usr/sbin/sendmail -oi -t")
                    or die "Can't fork for sendmail: $!\n";

print SENDMAIL <<"EOF";
From: Dan Langille <dan\@freshports.org>
To: Dan Langille <dan\@freebsddiary.org>
Subject: FreshPorts -- new users  - $StartDate

The following users were added yesterday:

$msgbody --

EOF

   close(SENDMAIL)     or warn "sendmail didn't close nicely";
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
              where firstlogin >= '$StartDate' \
                and firstlogin <= '$EndDate' \
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
