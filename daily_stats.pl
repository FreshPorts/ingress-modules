#!/usr/bin/perl -w
#
# $Id: daily_stats.pl,v 1.1.2.5 2004-01-12 19:02:25 dan Exp $
#
# Copyright (c) 2001-2003 DVL Software
#

use strict;
use lib "$ENV{HOME}/scripts";

use port;
use database; 
use DBI;

require config;

my $dbh = FreshPorts::Database::GetDBHandle();

my $sql;
my $sth;

$sql = "select DailyStatsCaculate()";

$sth = $dbh->prepare($sql);
$sth->execute ||
        die "Could not execute SQL $sql ... maybe invalid?";

$sth->fetchrow_array;

$sth->finish();
$dbh->commit();
$dbh->disconnect();
