#!/usr/bin/perl -w
#
# $Id: main-page-update.pl,v 1.3 2002-02-14 23:37:23 dan Exp $
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

	$sth = $dbh->prepare($sql) ||
		FreshPorts::Utilities::ReportError('warning', "Could not prepare SQL $sql ... maybe invalid?", 1);
	$sth->execute ||
		FreshPorts::Utilities::ReportError('warning', "Could not execute SQL $sql ... maybe invalid?", 1);

	@row=$sth->fetchrow_array;

	$sth->finish();
	$dbh->commit();

	$last_commit_date = $row[0];

	return $last_commit_date;
}

sub GetMaxCommitLogPortId($) {
	my $dbh = shift;

	my $sql;
	my $sth;
	my @row;
	my $MaxCommitLogPortId;

	$sql = "select max(commit_log_id) from commit_log_ports";
	$sth = $dbh->prepare($sql) ||
		FreshPorts::Utilities::ReportError('warning', "Could not prepare SQL $sql ... maybe invalid?", 1);
	$sth->execute ||
		FreshPorts::Utilities::ReportError('warning', "Could not execute SQL $sql ... maybe invalid?", 1);

	@row=$sth->fetchrow_array;

	$sth->finish();

	$MaxCommitLogPortId = $row[0];

	return $MaxCommitLogPortId;
}

sub GetLastCommitLogIdProcessed($) {
	my $dbh = shift;

	my $sql;
	my $sth;
	my @row;
	my $LastCommitLogIdProcessed;

	$sql = "select last_port_commit from housekeeping";
	$sth = $dbh->prepare($sql);
	$sth->execute ||
		FreshPorts::Utilities::ReportError('warning', "Could not execute SQL $sql ... maybe invalid?", 1);

	@row=$sth->fetchrow_array;

	$sth->finish();

	$LastCommitLogIdProcessed = $row[0];

	return $LastCommitLogIdProcessed;
}


my $dbh;

my $sql;
my $sth;
my $MaxCommitLogPortId;
my $LastCommitLogIdProcessed;

FreshPorts::Utilities::InitSyslog();

$dbh = FreshPorts::Database::GetDBHandle();

$MaxCommitLogPortId			= GetMaxCommitLogPortId      ($dbh);
$LastCommitLogIdProcessed	= GetLastCommitLogIdProcessed($dbh);

if (!defined($MaxCommitLogPortId)) {
	$MaxCommitLogPortId = 0;
}

if (!defined($LastCommitLogIdProcessed)) {
	$LastCommitLogIdProcessed = 0;
}

print "\$MaxCommitLogPortId       = '$MaxCommitLogPortId'\n";
print "\$LastCommitLogIdProcessed = '$LastCommitLogIdProcessed'\n";

if ($MaxCommitLogPortId > $LastCommitLogIdProcessed) {
	RefreshMainPage($dbh);
}

#
# daily summaries are suspended until I figure out a good way to handle them...
#
## create the daily summaries (if we have a port there..)
#if (keys %CommitLogPorts) {
#	FreshPorts::VerifyPort::CreateDailySummary($commit_date, $dbh);
#} else {
#	print "No ports found: CreateDailySummary not being called\n";
#}

$dbh->disconnect();