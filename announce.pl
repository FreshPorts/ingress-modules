#!/usr/bin/perl -w
#
# $Id: announce.pl,v 1.3.2.2 2002-09-09 18:08:11 dan Exp $
#
# Copyright (c) 1999-2000 DVL Software
#
use strict;
use DBI;
use database;
use constants;


my $dirname='';
my @USERS;
my $sql;
my $sth;
my @row;
my $Bcc;

my $ReportID = $FreshPorts::Constants::ReportIDAnnouncements;


sub SendAnnouncement($) {

  my $To = shift;

   open(SENDMAIL, "|/usr/sbin/sendmail -oi -t")
                    or die "Can't fork for sendmail: $!\n";

print SENDMAIL <<"EOF";
From: FreshPorts announcement <freshports-announce\@freshports.org>
To: $To
Subject: FreshPorts announcement

Folks,

This is me testing the new test facility.
--

You are recieving this message as part of the service
you joined at http://www.FreshPorts.org/ but if you no longer
wish to recieve such messages, please go to
http://www.FreshPorts.org/report-subscriptions.php

If a problem occurs, please send details, including the email
address in question, to postmaster\@freshports.org
EOF

   close(SENDMAIL)     or warn "sendmail didn't close nicely";

}

sub SendToEachListMember($) {

   my $dbh = shift;
   my $sth;
   my $sql;

   #
   # get a list of ports to update
   #
   # the following line restricts mailouts to just me.
   #               and users.id                      = 2

   $sql = "select users.email
             from users, report_subscriptions
            where length(users.email)            > 0
              and report_subscriptions.user_id   = users.id
              and emailbouncecount               = 0
              and report_subscriptions.report_id = $ReportID";

   print "sql is $sql\n";

   $sth = $dbh->prepare($sql);
   $sth->execute ||
           die "Could not execute SQL $sql ... maybe invalid?";

   while (@row=$sth->fetchrow_array) {
      SendAnnouncement($row[0]);
   }
}


      my $dbh = FreshPorts::Database::GetDBHandle();

      SendToEachListMember($dbh);

      $dbh->disconnect();

      print "\nmessage sent to users\n";

