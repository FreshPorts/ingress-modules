#!/usr/bin/perl -w
#
# $Id: announce.pl,v 1.3.2.6 2003-05-01 11:59:23 dan Exp $
#
# Copyright (c) 1999-2000 DVL Software
#
use strict;
use DBI;
use database;
use constants;
use email;

my $dirname='';
my @USERS;
my $sql;
my $sth;
my @row;
my $Bcc;

my $ReportID = $FreshPorts::Constants::ReportIDAnnouncements;


sub SendAnnouncement($) {

	my $To = shift;

	my $Body = "Folks,

FreshPorts Upgrade / Blacklist

Blacklist: 
The FreshPorts mail server was caught up in a blacklist recently.
This means you may not have been receiving FreshPorts as expected.

I urge you to review your watch list for any changes over the 
past two weeks for which you may not have received an update
notice.

For more information on the blacklist:

http://www.freebsddiary.org/freshports-release-2003.04.29.php

In the short term, FreshPorts mail is now going out from a
new mail server.


Upgrade:

The FreshPorts server has been upgraded.  Now you can have
one watch list per machine.  For details, see

http://www.freebsddiary.org/freshports-release-2003.04.29.php
http://www.freshports.org/release-2003-04-29.php

Cheers 



--

You are receiving this message as part of the service
you joined at http://www.FreshPorts.org/ but if you no longer
wish to receive such messages, please go to
http://www.FreshPorts.org/report-subscriptions.php

If a problem occurs, please send details, including the email
address in question, to postmaster\@freshports.org
";

	FreshPorts::email::SendMail('FreshPorts Announcement <FreshPorts-Announce@FreshPorts.org>', $To, 'HEADS UP: FreshPorts announcement', $Body, 'X-FreshPorts-Announcement: HEADS UP');
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


exit;
      my $dbh = FreshPorts::Database::GetDBHandle();

      SendToEachListMember($dbh);

      $dbh->disconnect();

      print "\nmessage sent to users\n";

