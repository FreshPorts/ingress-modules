#!/usr/bin/perl -w
#
# $Id: process_moved.pl,v 1.1.2.3 2003-12-31 17:15:30 dan Exp $
#
# Copyright (c) 2001-2003 DVL Software
#
# Parse /usr/ports/MOVED and load into ports_moved table
#

#we make a great deal of use of a global variable Updates.  We should fix that up.
use strict;

push (@INC, '~/scripts');

use lib "$ENV{HOME}/scripts";

require Sys::Syslog;

use db_utils;
use database;
use utilities;

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

	my $inputfile;

#	if (($#ARGV+1) == 1) {
#		$inputfile = $ARGV[0];
#		if (-f $inputfile) {
#		} else {
#			print "please specify an input file name which exists\n";
#			exit 1;
#		}
#	} else {
#		usage();
#		exit 1;
#	}

	my $dbh;

	print "Processing file [$inputfile]...\n";

	print "dbname = $FreshPorts::Config::dbname\n";

	$dbh = FreshPorts::Database::GetDBHandle();
	if ($dbh->{Active}) {

		parsefile($dbh, $inputfile);

# hmmm, this might be a good way to debug...
# issue a rollback after each attempt...
#
#		$dbh->rollback();
		$dbh->commit();

		$dbh->disconnect();
	}
}

sub parsefile ($) {
	my $dbh       = shift;
	my $inputfile = shift;

	my $line;
	my $result;
	my $From;
	my $To;
	my $Date;
	my $Why;

	my $ID;

	print "reading from STDIN...\n";
	while (defined(my $line = <STDIN> ) ) {
		# remove the trailing CR/LF
		chomp $line;

		if ($line =~ /^.*\/.*\|.*\|\d{4}-\d{2}-\d{2}\|.*$/) {
			print $line . "\n";

			($From, $To, $Date, $Why) = $line =~ /^(.*\/.*)\|(.*)\|(\d{4}-\d{2}-\d{2})\|(.*)$/;
			print "$From $To $Date $Why\n";
			$ID = AddMoved($dbh, $From, $To, $Date, $Why);
		}
	}
}

sub AddMoved($;$;$;$;$) {
	my $dbh    = shift;
	my $From   = $dbh->quote(shift);
	my $To     = $dbh->quote(shift);
	my $Date   = $dbh->quote(shift);
	my $Why    = $dbh->quote(shift);

	my $sth;
	my $sql;
	my @row;

	# quote everything going to the database
	$sql = "select PortsMovedAdd ($From, $To, $Date, $Why)";;
	$sth = $dbh->prepare($sql);
	if (!$sth->execute())  {
		FreshPorts::Utilities::ReportError('warning', "Could not execute sql", 1);
	}
	@row = $sth->fetchrow_array();   
	$sth->finish();

	return $row[0];
}