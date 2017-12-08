#!/usr/local/bin/perl -w
#
# $Id: test-master-port.pl,v 1.3 2007-12-30 18:41:59 dan Exp $
#
# Copyright (c) 2001-2007 DVL Software
#
# Verify that master-port is still working.
# Sometimes it breaks. So let's keep track of it.
#

use strict;

require Sys::Syslog;

use db_utils;
use database;
use utilities;
use system_status;

use DBI;

FreshPorts::Utilities::InitSyslog();


&main;
exit;

sub CheckMasterPorts($) {
	my $dbh = shift;

	my $sth;
	my $sql;
	my $row;

	# quote everything going to the database
	$sql = "SELECT master_port FROM ports_active WHERE name = 'bacula-client'";
	$sth = $dbh->prepare($sql);
	if (!$sth->execute())  {
		FreshPorts::Utilities::ReportError('warning', "Could not execute sql", 1);
	}
	$row = $sth->fetchrow_hashref();
	if ($row->{'master_port'} ne 'sysutils/bacula-server') {
		FreshPorts::Utilities::ReportErrorEmail('ERR', "The master port for bacula-client is not sysutils/bacula-server", 1, 0);
	}
}

#####
# Main Processing Routine
##### 

sub main {
	my $dbh;

	#
	# see if the system is online.
	# If not, exit.
	#
	my $SystemStatus = FreshPorts::SystemStatus->new();
	if (!$SystemStatus->Online()) {
		Sys::Syslog::syslog('warning', "not testing master port status: system is offline");
		exit 0;
	}

	$dbh = FreshPorts::Database::GetDBHandle($FreshPorts::Constants::DB_ConnectionType => $FreshPorts::Constants::DB_ConnectionType_ReadOnly);
	if ($dbh->{Active}) {

		CheckMasterPorts($dbh);

		$dbh->disconnect();
	}
}
