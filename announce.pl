#!/usr/bin/perl -w
#
# $Id: announce.pl,v 1.3 2002-01-06 07:21:05 dan Exp $
#
# Copyright (c) 1999-2000 DVL Software
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

  my $Bcc = shift;

   open(SENDMAIL, "|/usr/sbin/sendmail -oi -t")
                    or die "Can't fork for sendmail: $!\n";

print SENDMAIL <<"EOF";
From: FreshPorts announcement <freshports-announce\@freshports.org>
To: freshports-watch\@freshports.org
Bcc: $Bcc
Subject: FreshPorts announcement

Folks,

FreshPorts is looking for a new home, preferably in Ottawa. 
If you can host a single mini-tower box for us, please let us know.

Thank you.

p.s. we're upgrading the box from a P120 to a dual PPro 200.

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

sub CompileAnnouncementList($) {

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
      print "now processing @row\n";
      push @USERS, "$row[0]"
   }

   foreach $dirname (@USERS) {
      $Bcc .= $dirname . ',';
      print "found $dirname\n";
   }

   $Bcc .= 'freshports-watch@freshports.org';

   print "and the Bcc list is $Bcc\n";

   return $Bcc
}


      my $dbh = freshports_connect();

      $Bcc = CompileAnnouncementList($dbh);

      $dbh->disconnect();

#      $Bcc = "dan\@langille.org";
      SendAnnouncement($Bcc);

      print "message sent to users\n";

