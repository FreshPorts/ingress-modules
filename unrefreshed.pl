#!/usr/bin/perl -w

use strict;
use lib '/home/freshports.org/scripts/updates';
use ports;
 
use DBI;

use lib '/home/freshports.org/scripts';
use freshports_database;

sub SendNotice($;$) {
   my $Address = shift;
   my $count   = shift;

   open(SENDMAIL, "|/usr/sbin/sendmail -oi -t")
                    or die "Can't fork for sendmail: $!\n";

print SENDMAIL <<"EOF";
From: Dan Langille <dan\@freshports.org>
To: $Address
Subject: FreshPorts -- ports needing refresh

There are $count ports needing refresh.
EOF

   close(SENDMAIL)     or warn "sendmail didn't close nicely";
}


my $dbh = freshports_connect();

my $maxlength=0;
my $dirname='';
my $porttorefresh;
my @PORTS;
my $sql;
my $sth;
my @row;

#
# get a list of ports to update
#

$sql = "select count(*) \
        from ports \
        where ports.needs_refresh <> 0";

$sth = $dbh->prepare($sql);
$sth->execute ||
        die "Could not execute SQL $sql ... maybe invalid?";

@row=$sth->fetchrow_array;

if ($row[0] == 0) {
   print "nothing needs refresh\n";
} else {
   print "$row[0] ports need refresh\n";
   SendNotice("dan\@langille.org", $row[0]);
}

$sth->finish();
$dbh->disconnect();

