#!/usr/bin/perl
#
# $Id: special_processing_files.pm,v 1.1.2.6 2004-12-21 14:57:01 dan Exp $
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
		echo "applying special processing to $File";
		Sys::Syslog::syslog('notice', "applying special processing to $File");
		`/usr/bin/touch $FreshPorts::Config::MovedFileFlag`
	}

	if ($File eq 'ports/UPDATING') {
		echo "applying special processing to $File";
		Sys::Syslog::syslog('notice', "applying special processing to $File");
		`/usr/bin/touch $FreshPorts::Config::UpdatingFileFlag`
	}

 	if ($File eq 'ports/security/vuxml/vuln.xml') {
		echo "applying special processing to $File";
		Sys::Syslog::syslog('notice', "applying special processing to $File");
		`/usr/bin/touch $FreshPorts::Config::VuXMLFileFlag`
	}

 	if ($File eq 'CVSROOT/approvers') {
		echo "applying special processing to $File";
		Sys::Syslog::syslog('notice', "applying special processing to $File");
		`/bin/sh process_CVSROOT_approvers.sh`
	}
}

1;