#!/usr/bin/perl -w

use strict;
use ports;
 
use DBI;

my @row;

#my $dbh = DBI->connect('dbi:mysql:freshportschange','root','xyzzy');
my $dbh = DBI->connect('dbi:mysql:freshports','root','xyzzy');

my $sql = "select categories.name, ports.name, ports.status \
           from ports, categories \
           where ports.primary_category_id = categories.id \
           order by 1, 2";

my $sth = $dbh->prepare($sql);
$sth->execute ||
              die "Could not execute SQL $sql ... maybe invalid?";

while(@row=$sth->fetchrow_array) {
   print "$row[0] / $row[1] = $row[2]\n";
}

$dbh->disconnect();


