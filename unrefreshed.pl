#!/usr/bin/perl -w

use strict;
use lib '~/scripts';
#use lib '~/scripts/updates';

use port;
use database; 
use DBI;

#use freshports_database;

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
        where commit_log_ports.needs_refresh <> 0 \
          and ports.category_id              = categories.id \
		  and ports.element_id               = element.id \
		  and commit_log_ports.port_id       = ports.id \
    order by  category, port";

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

