#!/usr/bin/perl -w
#
# $Id: main-page-update.pl,v 1.8 2002-02-24 02:37:53 dan Exp $
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
	my $MaxCommitID;

	$sql = "select RecordLastestPortCommits('2002-01-01');";
	print "sql = $sql\n";

	if ($sth = $dbh->prepare($sql)) {
		if ($sth->execute) {
			@row=$sth->fetchrow_array;
		} else {
			FreshPorts::Utilities::ReportError('warning', "Could not execute SQL $sql ... maybe invalid?", 0);
		}
	} else {
		FreshPorts::Utilities::ReportError('warning', "Could not prepare SQL $sql ... maybe invalid?", 0);
	}

	$sth->finish();
	$dbh->commit();

	$MaxCommitID = $row[0];

	return $MaxCommitID
}

sub GetMaxCommitLogPortId($) {
	my $dbh = shift;

	my $sql;
	my $sth;
	my @row;
	my $MaxCommitLogPortId;

	$sql = "select max(commit_log_id) from commit_log_ports";
	if ($sth = $dbh->prepare($sql)) {
		if ( $sth->execute) {
			@row=$sth->fetchrow_array;

			$sth->finish();
		} else {
			FreshPorts::Utilities::ReportError('warning', "Could not execute SQL $sql ... maybe invalid?", 0)
		}
	} else {
		FreshPorts::Utilities::ReportError('warning', "Could not prepare SQL $sql ... maybe invalid?", 0);
	}

	$MaxCommitLogPortId = $row[0];

	return $MaxCommitLogPortId;
}

my $dbh;

my $sql;
my $sth;
my $MaxCommitLogPortId;
my $LastCommitLogIdProcessed;
my $housekeeping;
my $MaxCommitID;

FreshPorts::Utilities::InitSyslog();

while (1) {
	sleep 60;

	undef $MaxCommitID;

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

		$sql = "UPDATE housekeeping SET refresh_now = 0";
		if ($sth = $dbh->prepare($sql)) {
			if ($sth->execute) {
				$dbh->commit;
				$MaxCommitID = RefreshMainPage($dbh);
			} else {
	            FreshPorts::Utilities::ReportError('warning', "Could not execute SQL $sql ... maybe invalid?", 0);
			}
		} else {
			FreshPorts::Utilities::ReportError('warning', "Could not prepare SQL $sql ... maybe invalid?", 0);
		}
		
	}

	if (defined($MaxCommitID)) {
		print "update done... committing:";
		$dbh->commit();
		print " done!\n";
	} else {
		$dbh->rollback();
	}

	$dbh->disconnect();
}