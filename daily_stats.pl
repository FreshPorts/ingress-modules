#!/usr/bin/perl -w
#
# $Id: daily_stats.pl,v 1.1.2.1 2002-05-19 17:17:19 dan Exp $
#
# Copyright (c) 2001-2002 DVL Software
#

use strict;
use lib "$ENV{HOME}/scripts";

use port;
use database; 
use DBI;

require config;


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
$dbh->disconnect();
