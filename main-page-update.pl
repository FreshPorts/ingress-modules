#!/usr/bin/perl -w
#
# $Id: main-page-update.pl,v 1.10.2.4 2003-05-16 01:14:05 dan Exp $
#
# Copyright (c) 1999-2003 DVL Software
#

use strict;
use lib "$ENV{HOME}/scripts";
use DBI;
use database;
use utilities;
use housekeeping;
use cache;


my $dbh;

my $sql;
my $sth;
my $MaxCommitLogPortId;
my $LastCommitLogIdProcessed;
my $housekeeping;
my $MaxCommitID;
my $DaysRefreshed;

FreshPorts::Utilities::InitSyslog();

while (1) {
	print "sleeping\n";
	sleep 5;
	print "just woke up\n";

	undef $MaxCommitID;
	$DaysRefreshed = 0;

	$dbh = FreshPorts::Database::GetDBHandle();

	$housekeeping = FreshPorts::Housekeeping->new($dbh);
	$housekeeping->read();

	$MaxCommitLogPortId	= FreshPorts::Cache::GetMaxCommitLogPortId($dbh);

	if (!defined($housekeeping->{last_port_commit})) {
		print "last_port_commit was not defined\n";
		$housekeeping->{last_port_commit}	= 0;
		$housekeeping->{refresh_now}		= 1;
	}

	print "\$MaxCommitLogPortId               = '$MaxCommitLogPortId'\n";
	print "\$housekeeping->{last_port_commit} = '$housekeeping->{last_port_commit}'\n";
	print "\$housekeeping->{refresh_now}      = '$housekeeping->{refresh_now}'\n";

	if ($housekeeping->{refresh_now} || $MaxCommitLogPortId > $housekeeping->{last_port_commit}) {
		print "housekeeping shows a refresh is needed\n";
		$sql = "UPDATE housekeeping SET refresh_now = 0 where id = 1";
		if ($sth = $dbh->prepare($sql)) {
			if ($sth->execute) {
				print "refreshing main page now.\n";
				if ($housekeeping->{refresh_now} == $FreshPorts::Housekeeping::RefreshPorts) {
					my $MaxCommitID1 = FreshPorts::Cache::RefreshMainPage($FreshPorts::Housekeeping::RefreshPorts, $dbh);
					print "MaxCommitID1 ='$MaxCommitID1'\n"; 

					my $MaxCommitID2 = FreshPorts::Cache::RefreshMainPage($FreshPorts::Housekeeping::Refresh, $dbh);
					print "MaxCommitID2 ='$MaxCommitID2'\n"; 

					my $MaxCommitID;
					if ($MaxCommitID1 > $MaxCommitID2) {
						$MaxCommitID = $MaxCommitID1;
					} else {
						$MaxCommitID = $MaxCommitID2;
					}
					print "MaxCommitID ='$MaxCommitID'\n"; 
				}

				#
				# if we need to refresh the ports, we need to refresh 

				if ($housekeeping->{refresh_now} == $FreshPorts::Housekeeping::Refresh) {
					$MaxCommitID   = FreshPorts::Cache::RefreshMainPage($FreshPorts::Housekeeping::Refresh, $dbh);
				}
			} else {
	            FreshPorts::Utilities::ReportError('warning', "Could not execute SQL $sql ... maybe invalid?", 0);
			}
		} else {
			FreshPorts::Utilities::ReportError('warning', "Could not prepare SQL $sql ... maybe invalid?", 0);
		}
		
	}

	if ($housekeeping->{daily_refreshes}) {
		print "daily summary needed\n";
		$DaysRefreshed = FreshPorts::Cache::RefreshDailySummaries($dbh);
	} else {
		print "daily summary not necessary\n";
	}

	$dbh->commit();
	print " done!\n";

	$dbh->disconnect();
}