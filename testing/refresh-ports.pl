#!/usr/bin/perl -w

use lib '/usr/local/etc/freshports/updates';

use strict;
use ports;
 
use DBI;

my $BASEDIR = "/usr/ports";


my $IGNOREDCATS  = "Attic|distfiles|Mk|Tools|Templates|pkg|distributed|CVS|\\.\\.|\\.";


#my $STARTWITHDIR  = "/usr/ports/x11-fonts";
my $STARTWITHDIR = "";

#print "connecting to production... press enter to continue";
#<STDIN>;

#my $dbh = DBI->connect('dbi:mysql:freshportstest','root','xyzzy');
my $dbh = DBI->connect('dbi:mysql:freshports','root','xyzzy');

my $maxlength=0;
my $dirname='';
my @PORTS;
my $sql;
my $sth;
my @row;

#
# get a list of ports to update
#

$sql = "select ports.id, categories.name, ports.name \
        from ports, categories \
        where categories.id       = ports.primary_category_id \
          and ports.needs_refresh = 'Y'";

$sth = $dbh->prepare($sql);
$sth->execute ||
        die "Could not execute SQL $sql ... maybe invalid?";

while (@row=$sth->fetchrow_array) {
   print "now processing @row\n";
   push @PORTS, "$BASEDIR/$row[1]:$row[2]"
}

#  print "press enter to continue ";
#  <STDIN>;

my $port;

foreach $dirname (@PORTS) {
   print "found $dirname";

  ($dirname, $port) = split /:/,$dirname, 2;

  print " which becomes $dirname : $port\n";

#  print "press enter to continue ";
#  <STDIN>;

  RefreshPort($dirname, $port, $dbh);

#  print "press enter to continue ";
#  <STDIN>;
}

$dbh->disconnect();

`touch /usr/local/etc/freshports/msgs/lastupdate`
