#!/usr/bin/perl
#
# $Id: special_processing_files.pm,v 1.1.2.4 2004-10-03 16:03:23 dan Exp $
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
		`/usr/bin/touch $FreshPorts::Config::MovedFileFlag`
	}

	if ($File eq 'ports/UPDATING') {
		`/usr/bin/touch $FreshPorts::Config::UpdatingFileFlag`
	}

 	if ($File eq 'ports/security/vuxml/vuln.xml') {
		`/usr/bin/touch $FreshPorts::Config::VuXMLFileFlag`
	}

 	if ($File eq 'CVSROOT-ports/approvers') {
		`/bin/sh process_CVSROOT_approvers.sh`
	}
}

1;