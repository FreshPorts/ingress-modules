#!/usr/local/bin/perl
#
# $Id: database.pm,v 1.5 2006-12-17 12:04:00 dan Exp $
#
# Copyright (c) 2001-2003 DVL Software
#

package FreshPorts::Database;

use strict;
use utilities;
use DBI;
use Sys::Syslog;

require config;

sub GetDBHandle {
	my $dbh_pg = DBI->connect('DBI:Pg:dbname=' . $FreshPorts::Config::dbname . ';host=' . $FreshPorts::Config::host, $FreshPorts::Config::user, $FreshPorts::Config::password);
	if ($dbh_pg->{Active}) {
		$dbh_pg->{AutoCommit} = 0;

		if (!$dbh_pg) {
			FreshPorts::Utilities::ReportError('warning', "could not connect to $FreshPorts::Config::dbname", 1);
		}
	}

	return $dbh_pg;
}

1;