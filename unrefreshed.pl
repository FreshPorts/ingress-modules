#!/usr/bin/perl -w
#
# $Id: unrefreshed.pl,v 1.11 2002-03-12 15:42:35 dan Exp $
#
# Copyright (c) 2001-2002 DVL Software
#

use strict;
use lib "$ENV{HOME}/scripts";

use port;
use database; 
use DBI;

require config;


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


my $dbh = FreshPorts::Database::GetDBHandle();

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

$sql = "select ports.id, element.name as port, categories.name as category \
        from ports, categories, element, commit_log_ports \
        where ports.category_id              = categories.id \
		  and ports.element_id               = element.id \
		  and commit_log_ports.port_id       = ports.id \
          and commit_log_ports.needs_refresh <> 0 \
        order by category, port";

$sth = $dbh->prepare($sql);
$sth->execute ||
        die "Could not execute SQL $sql ... maybe invalid?";

my $rowcount = 0;
while (@row=$sth->fetchrow_array) {
	$rowcount++;
	print "id=$row[0] $row[2]/$row[1]\n";
}

if ($rowcount > 0) {
	print "\n$rowcount port[s] need[s] refresh\n";

	print "$ENV{HOME} is where we were\n";
}

$sth->finish();
$dbh->disconnect();

