#!/usr/bin/perl -w
#
# $Id: announce.pl,v 1.5 2002-04-25 03:08:19 dan Exp $
#
# Copyright (c) 1999-2002 DVL Software
#
use strict;
use DBI;

use lib '/home/freshports.org/scripts';
use freshports_database;


my $dirname='';
my @USERS;
my $sql;
my $sth;
my @row;
my $Bcc;


sub SendAnnouncement($) {

  my $To = shift;

   open(SENDMAIL, "|/usr/sbin/sendmail -oi -t")
                    or die "Can't fork for sendmail: $!\n";

print SENDMAIL <<"EOF";
From: FreshPorts announcement <freshports-announce\@freshports.org>
To: $To
Subject: FreshPorts announcement

Folks,

The testing at http://test.freshports.org/ has gone well.
The site is done and is ready to go into production.  We
have already gone through a trail migration of the user
logins and watch lists.  I'm not sure when we will go live
but it will probably be within the next couple of weeks.

In the meantime, if you haven't already checked the above
URL, I urge you to do so.  If you have any suggestions or
comment *now* is the time to submit them.

My thanks to the people who have been helping with the
testing and those who provided suggestions over the past
couple of months.  It has been very useful.

--

You are receiving this message as part of the service
you joined at http://freshports.org/ but if you no longer
wish to recieve such messages, please go to
http://freshports.org/customize.php3 and disable announcements.

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

   $sql = "select users.email               \
             from users                     \
            where length(users.email) > 0   \
              and emailsitenotices_yn = 'Y' \
              and emailbouncecount    = 0   \
            group by users.id";

   print "sql is $sql\n";

   $sth = $dbh->prepare($sql);
   $sth->execute ||
           die "Could not execute SQL $sql ... maybe invalid?";

   while (@row=$sth->fetchrow_array) {
#      SendAnnouncement($row[0]);
   }

}


      my $dbh = freshports_connect();

      SendToEachListMember($dbh);

      $dbh->disconnect();

      print "message sent to users\n";

