#!/usr/bin/perl -w
#
# $Id: process_vuxml.pl,v 1.1.2.5 2004-11-27 13:54:07 dan Exp $
#
# Copyright (c) 2001-2004 DVL Software
#
# Parse vuln.xml and load into vuxml table
#

#we make a great deal of use of a global variable Updates.  We should fix that up.
use strict;

require Sys::Syslog;

use db_utils;
use database;
use utilities;
use vuxml_parsing;
use vuxml_mark_commits;

use DBI;

FreshPorts::Utilities::InitSyslog();


&main;
exit;

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

		my $CommitMarker = FreshPorts::vuxml_mark_commits->new($dbh);

		my $i = $CommitMarker->ProcessEachRangeRecord();


# hmmm, this might be a good way to debug...
# issue a rollback after each attempt...
#
#		$dbh->rollback();
		$dbh->commit();

		$dbh->disconnect();
	}
}

