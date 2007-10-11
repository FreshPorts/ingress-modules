#!/usr/bin/perl -w
#
# $Id: test-master-port.pl,v 1.1 2007-10-11 18:57:27 dan Exp $
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
	if ($row->{'master_port'} ne 'bacula-server') {
		FreshPorts::Utilities::ReportErrorEmail('ERR', "The master port for bacula-client is not bacula-server", 1, 0);
	}
}

#####
# Main Processing Routine
##### 

sub main {
	my $dbh;

	$dbh = FreshPorts::Database::GetDBHandle();
	if ($dbh->{Active}) {

		CheckMasterPorts($dbh);

		$dbh->disconnect();
	}
}

