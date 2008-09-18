#!/usr/bin/perl
#
# $Id: special_processing_files.pm,v 1.9 2008-09-18 04:28:55 dan Exp $
#
# Copyright (c) 2001-2003 DVL Software
#

package FreshPorts::SpecialProcessingFiles;

use strict;
use constants;
use utilities;
use config;
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

 	if ($File eq $FreshPorts::Constants::VUXML) {
 		# no need to fetch this file, it's in the ports tree.
 		# fetching such files is part of the usual process.
		print "applying special processing to $File\n";
		Sys::Syslog::syslog('notice', "applying special processing to $File");
		`/usr/bin/touch $FreshPorts::Config::VuXMLFileFlag`;
		`/usr/bin/touch $FreshPorts::Config::JobWaiting`;
	}

 	if ($File eq $FreshPorts::Constants::CVSROOT_Approvers && $Repository eq $FreshPorts::Constants::Repository_Ports) {
 		# must fetch this file.  It's not in the ports tree.
		print "applying special processing to $File\n";
		Sys::Syslog::syslog('notice', "applying special processing to $File");
 		my $DESTDIR = $FreshPorts::Config::TMP;
 		my $SRCDIR  = dirname ($FreshPorts::Constants::CVSROOT_Ports_Approvers);
 		my $FILE    = basename($FreshPorts::Constants::CVSROOT_Ports_Approvers);
 		if (FreshPorts::Utilities::FetchFile($DESTDIR, $SRCDIR, $FILE, $Revision)) {
 			print "$DESTDIR/$FILE is our friend\n";
			`/bin/sh process_CVSROOT_approvers.sh $DESTDIR/$FILE`;
 			print "is $DESTDIR/$FILE still our friend?\n";
			#
			# We don't need to set the Job Waiting flag for this file.
			# Processing is simple and does not involve the database.
			#
		} else {
			Sys::Syslog::syslog('notice', "special processing to $File will not proceed becaused of fetch failures.");
			$ErrorCode = 1;
		}
	}

 	if ($File eq $FreshPorts::Constants::Categories) {
		print "applying special processing to $File\n";
		Sys::Syslog::syslog('notice', "applying special processing to $File by creating $FreshPorts::Config::WWWENPortsCategoriesFlag");
 		# fetch this file.  It's not in the ports tree
 		my $DESTDIR = $FreshPorts::Config::TMP;
 		my $SRCDIR  = dirname($FreshPorts::Constants::Categories);
 		my $FILE    = basename($FreshPorts::Constants::Categories);
 		if (FreshPorts::Utilities::FetchFile($DESTDIR, $SRCDIR, $FILE, $Revision)) {
			`/usr/bin/touch $FreshPorts::Config::WWWENPortsCategoriesFlag`;
 			`/usr/bin/touch $FreshPorts::Config::JobWaiting`;
		} else {
			Sys::Syslog::syslog('notice', "special processing to $File will not proceed becaused of fetch failures.");
			$ErrorCode = 1;
		}
	}
	
	return $ErrorCode;

}

1;