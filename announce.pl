#!/usr/bin/perl -w
#
# $Id: announce.pl,v 1.3.2.4 2002-11-24 17:14:57 dan Exp $
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

A new reporting facility has been created.  This allows
new reports to be easily added.  It also puts all of your
subscriptions in one easy place:

   http://www.FreshPorts.org/report-subscriptions.php

Please visit the above URL to ensure you are subscribed to the
reports you want.

HEADS UP: If you subscribed or changed your report preferences
on Monday September 9, 2002 around 2-3 pm EST, you should review
your settings.  This was about the time which we converted the 
database.  If you made no changes on this day, your previous settings
should have been copied over to the new setup.
--

You are recieving this message as part of the service
you joined at http://www.FreshPorts.org/ but if you no longer
wish to recieve such messages, please go to
http://www.FreshPorts.org/report-subscriptions.php

If a problem occurs, please send details, including the email
address in question, to postmaster\@freshports.org
";

	FreshPorts::email::SendMail('FreshPorts Announcement <FreshPorts-Announce@FreshPorts.org>', $To, 'HEADS UP: FreshPorts announcement', $Body);
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

