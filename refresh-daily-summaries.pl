#!/usr/bin/perl -w
#
# $Id: refresh-daily-summaries.pl,v 1.1.2.1 2003-09-16 11:51:12 dan Exp $
#
# Copyright (c) 1999-2003 DVL Software
#

use strict;
use lib "$ENV{HOME}/scripts";
use DBI;
use database;
use cache;

my $dbh;

my $DaysRefreshed;

FreshPorts::Utilities::InitSyslog();

$dbh = FreshPorts::Database::GetDBHandle();

$DaysRefreshed = FreshPorts::Cache::RefreshDailySummaries($dbh);

$dbh->rollback();

$dbh->disconnect();
