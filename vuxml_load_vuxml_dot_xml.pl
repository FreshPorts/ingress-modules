#!/usr/bin/perl -w
#
# $Id: vuxml_load_vuxml_dot_xml.pl,v 1.1.2.1 2004-10-03 01:45:09 dan Exp $
#
# Copyright (c) 2001-2004 DVL Software
#
# Parse vuln.xml and load into vuxml table
#

#we make a great deal of use of a global variable Updates.  We should fix that up.
use strict;

push (@INC, '~/scripts');

use lib "$ENV{HOME}/scripts";

require Sys::Syslog;

use db_utils;
use database;
use utilities;
use vuxml_parsing;

use DBI;

FreshPorts::Utilities::InitSyslog();


&main;
exit;

sub usage {
	print "USAGE : $0 INPUTFILE\n";
}

#####
# Main Processing Routine
##### 

sub main {

	my $dbh;

	print "dbname = $FreshPorts::Config::dbname\n";

	$dbh = FreshPorts::Database::GetDBHandle();
	if ($dbh->{Active}) {

		EmptyVuXML($dbh);

		my $v = FreshPorts::vuxml_parsing->new(Stream => *STDIN, DBHandle => $dbh);
		$v->parse_xml();

# hmmm, this might be a good way to debug...
# issue a rollback after each attempt...
#
#		$dbh->rollback();
		$dbh->commit();

		$dbh->disconnect();
	}
}

sub EmptyVuXML($) {
	my $dbh = shift;

	my $sth;
	my $sql;

	# quote everything going to the database
	$sql = "DELETE FROM vuxml";
	$sth = $dbh->prepare($sql);
	if (!$sth->execute())  {
		FreshPorts::Utilities::ReportError('warning', "Could not execute sql", 1);
	}
}
