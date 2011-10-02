#!/usr/bin/perl -w
#
# $Id: process_vuxml.pl,v 1.3 2011-10-02 17:29:20 dan Exp $
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
		FreshPorts::Utilities::ReportError('warning', "Could not execute sql: " . $sql, 1);
	}

	$sql = "DELETE FROM ports_vulnerable";
	$sth = $dbh->prepare($sql);
	if (!$sth->execute())  {
		FreshPorts::Utilities::ReportError('warning', "Could not execute sql: " . $sql, 1);
	}
}

#####
# Main Processing Routine
##### 

sub main {
	my $dbh;
	my $WipeExistingVuXMLEntries = 0;

	if (($#ARGV+1) >= 1) {
		if ($ARGV[0] eq '-w') {
			$WipeExistingVuXMLEntries = 1;
			print "Existing VuXML entries will be deleted\n";
		}
	}

	print "dbname = $FreshPorts::Config::dbname\n";

	$dbh = FreshPorts::Database::GetDBHandle();
	if ($dbh->{Active}) {

		if ($WipeExistingVuXMLEntries) {
			EmptyVuXML($dbh);
		}

		my $v = FreshPorts::vuxml_parsing->new(Stream        => *STDIN, 
                                               DBHandle      => $dbh,
                                               UpdateInPlace => !$WipeExistingVuXMLEntries);
		$v->parse_xml();

		if ($WipeExistingVuXMLEntries) {
			my $CommitMarker = FreshPorts::vuxml_mark_commits->new($dbh);
			my $i = $CommitMarker->ProcessEachRangeRecord();
			$CommitMarker->ClearCachedEntries();
		}
		


# hmmm, this might be a good way to debug...
# issue a rollback after each attempt...
#
#		$dbh->rollback();
		$dbh->commit();

		$dbh->disconnect();
	}
}

