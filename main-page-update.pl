#!/usr/bin/perl -w
#
# $Id: main-page-update.pl,v 1.5 2002-02-18 04:12:23 dan Exp $
#
# Copyright (c) 1999-2002 DVL Software
#

use strict;
use lib "$ENV{HOME}/scripts";
use DBI;
use database;
use utilities;
use housekeeping;

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

my $dbh;

my $sql;
my $sth;
my $MaxCommitLogPortId;
my $LastCommitLogIdProcessed;
my $housekeeping;

FreshPorts::Utilities::InitSyslog();

while (1) {

	$dbh = FreshPorts::Database::GetDBHandle();

	$housekeeping = FreshPorts::Housekeeping->new($dbh);
	$housekeeping->read();

	$MaxCommitLogPortId	= GetMaxCommitLogPortId      ($dbh);

	if (!defined($housekeeping->{last_port_commit})) {
		print "last_port_commit was not defined\n";
		$housekeeping->{last_port_commit}	= 0;
		$housekeeping->{refresh_now}		= 1;
	}

	print "\$MaxCommitLogPortId               = '$MaxCommitLogPortId'\n";
	print "\$housekeeping->{last_port_commit} = '$housekeeping->{last_port_commit}'\n";
	print "\$housekeeping->{refresh_now}      = '$housekeeping->{refresh_now}'\n";

	if ($housekeeping->{refresh_now} || $MaxCommitLogPortId > $housekeeping->{last_port_commit}) {
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

	sleep 60;
}