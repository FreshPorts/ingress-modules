#!/usr/bin/perl -w
#
# $Id: main-page-update.pl,v 1.1 2002-02-14 19:26:32 dan Exp $
#
# Copyright (c) 1999-2002 DVL Software
#

use strict;
use lib "$ENV{HOME}/scripts";
use DBI;
use database;
use utilities;

sub RefreshMainPage($) {
	my $dbh = shift;

	my $sql;
	my $sth;
	my @row;
	my $last_commit_date;

	$sql = "select RecordLastestPortCommits('2002-01-01');";
	print "sql = $sql\n";

	$sth = $dbh->prepare($sql);
	$sth->execute ||
		FreshPorts::Utilities::ReportError('warning', "Could not execute SQL $sql ... maybe invalid?", 1);

	@row=$sth->fetchrow_array;

	$sth->finish();
	$dbh->commit();

	$last_commit_date = $row[0];

	return $last_commit_date;
}


my $dbh;

my $sql;
my $sth;

FreshPorts::Utilities::InitSyslog();

$dbh = FreshPorts::Database::GetDBHandle();

RefreshMainPage($dbh);

## create the daily summaries (if we have a port there..)
#if (keys %CommitLogPorts) {
#	FreshPorts::VerifyPort::CreateDailySummary($commit_date, $dbh);
#} else {
#	print "No ports found: CreateDailySummary not being called\n";
#}

$dbh->disconnect();

