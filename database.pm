#!/usr/bin/perl
#
# $Id: database.pm,v 1.4 2002-02-02 04:46:41 dan Exp $
#
# Copyright (c) 2001 DVL Software
#

package FreshPorts::Database;

use strict;
use utilities;
use DBI;
use Sys::Syslog;

require config;

sub GetDBHandle {
	my $dbh_pg = DBI->connect('DBI:Pg:dbname=' . $FreshPorts::Config::dbname, $FreshPorts::Config::user, $FreshPorts::Config::password);
	if ($dbh_pg->{Active}) {
		$dbh_pg->{AutoCommit} = 0;

		if (!$dbh_pg) {
			FreshPorts::Utilities::ReportError('warning', "could not connect to FreshPorts2", 1);
		}
	}

	return $dbh_pg;
}

1;