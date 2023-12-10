#!/usr/local/bin/perl -w
#
# $Id: special_processing_files.pm,v 1.9 2008-09-18 04:28:55 dan Exp $
#
# Copyright (c) 2001-2003 DVL Software
#

package FreshPorts::SpecialProcessingFiles;

use strict;
use FreshPorts::constants;
use FreshPorts::utilities;
use FreshPorts::config;
use File::Basename;

sub Eat($;$;$;$;$) {
	my $dbh        = shift;
	my $Action     = shift;
	my $File       = shift;
	my $Revision   = shift;
	my $Repository = shift;
	
	my $ErrorCode = 0;

	#
	# By the time we have been called, the file has been fetched
	# so we are free to process as we please.

	# we don't use the DB yet, but we have this code here in case we do.
	my $sth;
	my $sql;
	my @row;

	Sys::Syslog::syslog('notice', 'Entering ' . __FILE__ . "::Eat\n");
	if ($File eq $FreshPorts::Constants::PORTS_MOVED) {
 		# no need to fetch this file, it's in the ports tree.
 		# fetching such files is part of the usual process.	
		print "applying special processing to $File\n";
		Sys::Syslog::syslog('notice', "applying special processing to $File");
		`/usr/bin/touch $FreshPorts::Config::MovedFileFlag`;
		`/usr/bin/touch $FreshPorts::Config::JobWaiting`;
	}

	if ($File eq $FreshPorts::Constants::PORTS_UPDATING) {
 		# no need to fetch this file, it's in the ports tree.
 		# fetching such files is part of the usual process.
		print "applying special processing to $File\n";
		Sys::Syslog::syslog('notice', "applying special processing to $File");
		`/usr/bin/touch $FreshPorts::Config::UpdatingFileFlag`;
		`/usr/bin/touch $FreshPorts::Config::JobWaiting`;
	}

 	if ($File =~ $FreshPorts::Constants::VUXML) {
 		# no need to fetch this file, it's in the ports tree.
 		# fetching such files is part of the usual process.
		print "applying special processing to $File\n";
		Sys::Syslog::syslog('notice', "applying special processing to $File");
		`/usr/bin/touch $FreshPorts::Config::VuXMLFileFlag`;
		`/usr/bin/touch $FreshPorts::Config::JobWaiting`;
	}

	#
	# When Mk/bsd.default-versions.mk changes, invoke this script
	# re https://github.com/FreshPorts/freshports/issues/509
	#
 	if ($File eq $FreshPorts::Constants::DEFAULT_VERSION) {
		print "applying special processing to $File\n";
		Sys::Syslog::syslog('notice', "applying special processing to $File by creating $FreshPorts::Config::DefaultVersionsFlag");
		
		`/usr/bin/touch $FreshPorts::Config::DefaultVersionsFlag`;
		`/usr/bin/touch $FreshPorts::Config::JobWaiting`;
		# to be completed
	}

	Sys::Syslog::syslog('notice', 'Returning from ' . __FILE__ . "::Eat with ErrorCode='$ErrorCode'\n");
	return $ErrorCode;

}

1;
