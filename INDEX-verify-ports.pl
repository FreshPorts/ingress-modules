#!/usr/bin/perl -w
#
# $Id: INDEX-verify-ports.pl,v 1.1 2002-03-03 23:52:28 dan Exp $
#
# Copyright (c) 2001-2002 DVL Software
#

use strict;
use lib "$ENV{HOME}/scripts";

use port;
use database;
use utilities;
use DBI;

require config;

sub ExtractPortFromLine($) {
	my $IndexLine = shift;

	(my $version, my $pathname, my $rest) = split(/\|/, $IndexLine);
#	print "$version, $pathname, $rest\n";
	print "$pathname => ";

	(my $extra, my $usr, my $ports, my $category, my $port) = split ("/", $pathname);

	return "$category/$port";
}

my $sth;
my $sql;
my $IndexLine;

my $dbh = FreshPorts::Database::GetDBHandle();

if ($dbh) {
	print "connected\n";

	print "now setting up things....\n";

#	$dbh->begin() || 
#		FreshPorts::Utilities::ReportError('warning', "Could not execute SQL $sql ... maybe invalid?", 1);

	$sql = "select PortVerifyBegin()";
	$sth = $dbh->prepare($sql);
	$sth->execute ||
		FreshPorts::Utilities::ReportError('warning', "Could not execute SQL $sql ... maybe invalid?", 1);


	print "now processing incoming data...\n";
	while (defined(my $IndexLine = <STDIN> ) ) {
		# remove the trailing CR/LF
		$IndexLine =~ s/\n//g;

		my $result = ExtractPortFromLine($IndexLine);
		print "$result\n";

		(my $category, my $port) = split ("/", $result);

		$sql = "select PortVerifyAddOne('$category', '$port')";
		$sth = $dbh->prepare($sql);
		$sth->execute ||
			FreshPorts::Utilities::ReportError('warning', "Could not execute SQL $sql ... maybe invalid?", 1);

	}

	$dbh->commit() ||
		FreshPorts::Utilities::ReportError('warning', "Could not execute SQL $sql ... maybe invalid?", 1);

	print "now calculating results...\n";
	$sql = "select PortsVerifyProcess()";
	$sth = $dbh->prepare($sql);
	$sth->execute ||
        FreshPorts::Utilities::ReportError('warning', "Could not execute SQL $sql ... maybe invalid?", 1);

	print "done!\n";

	$dbh->commit() ||
		FreshPorts::Utilities::ReportError('warning', "Could not execute SQL $sql ... maybe invalid?", 1);

	$sth->finish();
	$dbh->disconnect();
} else {
	print "Cannot connect to Postgres server: $DBI::errstr\n";
	print " db connection failed\n";
}
