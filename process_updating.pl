#!/usr/bin/perl
#
# $Id: process_updating.pl,v 1.1.2.8 2005-01-08 14:30:10 dan Exp $
#
# Copyright (c) 2004 DVL Software
#
# Original code by Travis Campbell (HCoyote).
#
# Parse /usr/ports/UPDATING and load into ports_updating table
#
# pipe the UPDATING file into this script.  Output is for diagnostics only 
# and can be dev/null'd.
#


use strict;
use warnings;

require Sys::Syslog;

use db_utils;
use database;
use utilities;
use config;

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

		EmptyUpdating($dbh);

		parsefile($dbh);

# hmmm, this might be a good way to debug...
# issue a rollback after each attempt...
#
#		$dbh->rollback();
		$dbh->commit();

		$dbh->disconnect();
	}
}

sub parsefile ($) {
	my $dbh = shift;

	my $version;

	# slurp in UPDATING.
	my @lines = <STDIN>;
	chomp @lines;

	# start going through the file;
	for (my $i = 0; $i < scalar @lines; $i++) {
		# encounter a line with a date
		if ($lines[$i] =~ m/^(\d{8}):/) {
			my ($affects, $author, $msg);
			my $date = $1;
			# parse the stuff between lines with dates
			for (my $j = $i + 1; $j < scalar @lines; $j++) {
				my $line = $lines[$j];
				last if ($line =~ m/^\d{8}:/);
				last if ($line =~ m/^\$FreeBSD:/);
				if ($line =~ m/\s+AFFECTS:\s+(.*)$/){
					$affects = $1; 
				} elsif ($line =~ m/\s+AUTHOR:\s+(.*)$/) {
					$author = $1;
				} else {
					$msg .= $line . "\n";
				}
				#} elsif ($line =~ m/^(?:\s+)?(.*)$/ or $line =~ m/(^$)/) {
				#	$msg .= $1 . "\n";
				#} 
			}

			# lets deal with port names
			my @ports;
			my @affects_match =  split(/,?\s+/, $affects);

			# take the split up $affects tokens and see if they look
			# like ports entries.
			for my $part (@affects_match) {
				if ($part =~ m^/^) {
					$part =~ s/[()]//g;  # strip out unmentionables
					print "port found: '$part'\n";
					if ($part =~ m%[\*\{\}\[\],]%) {
						# suggested by mat@ for parsing
						# affect ports that look like shell
						# globs
						chdir "$FreshPorts::Config::path_to_ports";
						push @ports, glob $part;
					} else {
						push @ports, $part;
					}
				}
			}

			my $ID = AddUpdating($dbh, $date, $affects, $author, $msg);

			print "Date    : $date\n";
			print "Affects : $affects\n";
			for my $port (@ports) {
				print "$date THE PORTS ARE: $port ($ID)\n";
				AddUpdatingXref($dbh, $ID, $port);
			}
			if ($author) {
				print "Author  : $author\n";
			} else { 
				print "Author  : unknown\n";
			}
			print "Message : $msg\n";
			print "-"x72, "\n";


		} elsif ($lines[$i] =~ m%^(\$FreeBSD: .+ \$)$%){
			# get the UPDATING version in case we want it later.
			$version = $1;
		}
	}
}

sub AddUpdating($;$;$;$;$) {
	my $dbh     = shift;
	my $Date    = $dbh->quote(shift);
	my $Affects = $dbh->quote(shift);
	my $Author  = $dbh->quote(shift);
	my $Reason  = $dbh->quote(shift);

	my $sth;
	my $sql;
	my @row;

	# quote everything going to the database
	$sql = "select PortsUpdatingAdd($Date\:\:date, $Affects, $Author, $Reason)";
	$sth = $dbh->prepare($sql);
	if (!$sth->execute())  {
		FreshPorts::Utilities::ReportError('warning', "Could not execute sql: '$sql'", 1);
	}
	@row = $sth->fetchrow_array();   
	$sth->finish();

	return $row[0];
}

sub AddUpdatingXref($;$;$) {
	my $dbh             = shift;
	my $PortsUpdatingID = $dbh->quote(shift);
	my $Port            = $dbh->quote(shift);

	my $sth;
	my $sql;
	my @row;

	# quote everything going to the database
	$sql = "select PortsUpdatingPortsXrefAdd($PortsUpdatingID, $Port)";
	$sth = $dbh->prepare($sql);
	if (!$sth->execute())  {
		FreshPorts::Utilities::ReportError('warning', "Could not execute sql: '$sql'", 1);
	}
	@row = $sth->fetchrow_array();   
	$sth->finish();

	return $row[0];
}

sub EmptyUpdating($) {
	my $dbh = shift;

	my $sth;
	my $sql;

	# quote everything going to the database
	$sql = "DELETE FROM ports_updating";
	$sth = $dbh->prepare($sql);
	if (!$sth->execute())  {
		FreshPorts::Utilities::ReportError('warning', "Could not execute sql", 1);
	}
}
