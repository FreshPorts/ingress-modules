#!/usr/bin/perl -w
#
# $Id: daily_stats.pl,v 1.1.2.4 2003-05-16 01:14:02 dan Exp $
#
# Copyright (c) 2001-2003 DVL Software
#

use strict;
use lib "$ENV{HOME}/scripts";

use port;
use database; 
use DBI;

require config;

print "\$FreshPorts::Config::dbname='$FreshPorts::Config::dbname'\n";
print "\$FreshPorts::Config::user='$FreshPorts::Config::user'\n";
print "\$FreshPorts::Config::password='$FreshPorts::Config::password'\n";


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

$sql = "select DailyStatsCaculate()";

$sth = $dbh->prepare($sql);
$sth->execute ||
        die "Could not execute SQL $sql ... maybe invalid?";

my $rowcount = 0;
$sth->fetchrow_array;

$sth->finish();
$dbh->commit();
$dbh->disconnect();
