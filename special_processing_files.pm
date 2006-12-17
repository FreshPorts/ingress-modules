#!/usr/bin/perl
#
# $Id: special_processing_files.pm,v 1.2 2006-12-17 12:04:03 dan Exp $
#
# Copyright (c) 2001-2003 DVL Software
#

package FreshPorts::SpecialProcessingFiles;

use strict;
use utilities;
use config;

sub Eat($;$;$;$) {
	my $dbh      = shift;
	my $Action   = shift;
	my $File     = shift;
	my $Revision = shift;

	#
	# By the time we have been called, the file has been fetched
	# so we are free to process as we please.

	# we don't use the DB yet, but we have this code here in case we do.
	my $sth;
	my $sql;
	my @row;

	if ($File eq 'ports/MOVED') {
		print "applying special processing to $File";
		Sys::Syslog::syslog('notice', "applying special processing to $File");
		`/usr/bin/touch $FreshPorts::Config::MovedFileFlag`;
		`/usr/bin/touch $FreshPorts::Config::JobWaiting`;
	}

	if ($File eq 'ports/UPDATING') {
		print "applying special processing to $File";
		Sys::Syslog::syslog('notice', "applying special processing to $File");
		`/usr/bin/touch $FreshPorts::Config::UpdatingFileFlag`;
		`/usr/bin/touch $FreshPorts::Config::JobWaiting`;
	}

 	if ($File eq 'ports/security/vuxml/vuln.xml') {
		print "applying special processing to $File";
		Sys::Syslog::syslog('notice', "applying special processing to $File");
		`/usr/bin/touch $FreshPorts::Config::VuXMLFileFlag`;
		`/usr/bin/touch $FreshPorts::Config::JobWaiting`;
	}

 	if ($File eq 'CVSROOT/approvers') {
		print "applying special processing to $File";
		Sys::Syslog::syslog('notice', "applying special processing to $File");
		`/bin/sh process_CVSROOT_approvers.sh`;
		#
		# We don't need to set the Job Waiting flag for this file.
		# Processing is simple and does not involve the database.
		#
	}
}

1;