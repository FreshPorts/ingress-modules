#!/usr/bin/perl -w
#
# $Id: refresh-daily-summaries.pl,v 1.1.2.2 2004-02-07 06:31:23 dan Exp $
#
# Copyright (c) 1999-2003 DVL Software
#

use strict;
use lib "$ENV{HOME}/scripts";
use DBI;
use database;
use cache;
use commit_log_ports_ignore;
use system_status;
my $dbh;

my $DaysRefreshed;

#
# see if the system is online.
# If not, exit.
#
my $SystemStatus = FreshPorts::SystemStatus->new();
if (!$SystemStatus->Online()) {
	exit 0;
}

FreshPorts::Utilities::InitSyslog();

$dbh = FreshPorts::Database::GetDBHandle();

$DaysRefreshed = FreshPorts::Cache::RefreshDailySummaries($dbh);

$dbh->rollback();

$dbh->disconnect();
