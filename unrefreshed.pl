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

$sql = "select ports.id, ports.name as port, categories.name as category \
        from ports, categories \
        where ports.needs_refresh      <> 0 \
          and ports.primary_category_id = categories.id
    order by  category, port";

$sth = $dbh->prepare($sql);
$sth->execute ||
        die "Could not execute SQL $sql ... maybe invalid?";

my $rowcount = 0;
while (@row=$sth->fetchrow_array) {
	$rowcount++;
	print "id=$row[0] $row[1]/$row[2]\n";
}

if ($rowcount > 0) {
	print "\n\n There are $rowcount ports requiring refresh\n"
}

$sth->finish();
$dbh->disconnect();

