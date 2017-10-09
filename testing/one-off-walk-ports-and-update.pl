#!/usr/local/bin/perl -w

use strict;
use ports;
 
use DBI;

#my $dbh = DBI->connect('dbi:mysql:freshportstest','root','xyzzy');
my $dbh = DBI->connect('dbi:mysql:freshports','root','xyzzy');

RefreshPort("/usr/ports/devel", "gdb-m68k", $dbh);

$dbh->disconnect();


