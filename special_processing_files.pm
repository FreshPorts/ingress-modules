#!/usr/bin/perl
#
# $Id: special_processing_files.pm,v 1.1.2.1 2003-12-31 22:49:38 dan Exp $
#
# Copyright (c) 2001-2003 DVL Software
#

package FreshPorts::SpecialProcessingFiles;

use strict;
use utilities;

%FreshPorts::SpecialProcessingFiles::Files = (
	"ports/MOVED"		=> 1,
);


sub Eat($;$;$;$) {
	my $dbh      = shift;
	my $Action   = shift;
	my $File     = shift;
	my $Revision = shift;

	# we don't use the DB yet, but we have this code here in case we do.
	my $sth;
	my $sql;
	my @row;

	if (defined($FreshPorts::SpecialProcessingFiles::Files{$File})) {
		`/usr/bin/touch $FreshPorts::Config::MovedFileFlag`
	}
}

1;