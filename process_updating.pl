#!/usr/bin/perl
#
# $Id: process_updating.pl,v 1.1.2.2 2004-08-01 23:45:01 dan Exp $
#
# Copyright (c) 2004 DVL Software
#
# Original code by Travis Campbell (HCoyote).
#
# Parse /usr/ports/UPDATING and load into ports_updating table
#


use strict;
use warnings;

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
	my @dates;

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
			my @affects_match =  split(/\s/, $affects);

			# take the split up $affects tokens and see if they look
			# like ports entries.
			for my $part (@affects_match) {
				if ($part =~ m^/^) {
					if ($part =~ m%[\*\{\}\[\],]%) {
						# suggested by mat@ for parsing
						# affect ports that look like shell
						# globs
						chdir "/usr/ports";
						push @ports, glob $part;
					} else {
						push @ports, $part;
					}
				}
			}


			# store for later.
			push @dates, {date      => $date, 
					author  => $author,
					port    => \@ports,
					affects => $affects, 
					msg     => $msg};

			my $ID = AddUpdating($dbh, $date, $affects, $author, $msg);


		} elsif ($lines[$i] =~ m%^(\$FreeBSD: .+ \$)$%){
			# get the UPDATING version in case we want it later.
			$version = $1;
		}
	}

	# ta da.  data parsed, now we can do whatever with it.
	for my $date (@dates) {
		print "Date    : $date->{date}\n";
		print "Affects : $date->{affects}\n";
		print "Port    : ";
		if (scalar @{$date->{port}} > 1) {
			print #"(", scalar @{$date->{port}}, ")", map {"$_ "} @{$date->{port}};
			print "\n";
		} elsif (scalar @{$date->{port}} == 1) {
			print $date->{port}->[0],"\n";
		} else {
			print "Unknown port\n";
		}

		if (defined $date->{author}) {
			print "Author  : $date->{author}\n";
		} else { 
			print "Author  : unknown\n";
		}
		print "Message : $date->{msg}\n";
		print "-"x72, "\n";
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
	$sql = "select PortsUpdatingAdd($Date\:\:date, $Affects, $Author, $Reason)";;
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
