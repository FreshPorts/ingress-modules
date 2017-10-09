#!/usr/local/bin/perl
#
# $Id: test_DailySummary.pl,v 1.3 2002-04-01 21:16:21 dan Exp $
#
# Copyright (c) 1999-2002 DVL Software
#
use strict;
use DBI;
use element;

require config;
require database;
require verifyport;

my ($dbh, $element);

$dbh = FreshPorts::Database::GetDBHandle();

FreshPorts::Cache::CreateDailySummary('2001-12-4', $dbh);

$dbh->disconnect();
