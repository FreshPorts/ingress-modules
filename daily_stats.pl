#!/usr/bin/perl -w
#
# $Id: daily_stats.pl,v 1.1.2.6 2004-02-07 06:31:22 dan Exp $
#
# Copyright (c) 2001-2003 DVL Software
#

use strict;
use lib "$ENV{HOME}/scripts";

use port;
use database; 
use DBI;
use commit_log_ports_ignore;
use system_status;

require config;

#
# see if the system is online.
# If not, exit.
#
my $SystemStatus = FreshPorts::SystemStatus->new();
if (!$SystemStatus->Online()) {
	exit 0;
}

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
