#!/usr/bin/perl -w 
#
# $Id: vuxml_ident.pl,v 1.2 2006-12-17 12:04:04 dan Exp $
#
# Copyright (c) 2005 DVL Software
#
# Parse vuln.xml and load into vuxml table
#

use strict;

sub vuln_ident($) {
	#
	# From code originally written by Harold Paulson
	#

	my $VUXML = shift;

	my %ident;

	my $IDENT_BIN = '/usr/bin/ident';

	open(VUXML, "$IDENT_BIN $VUXML |") 
		|| die("ERROR: Cound not ident $VUXML: $!\n");

	while (<VUXML>) {
		next unless m#^\s+\$FreeBSD: .*ports/security/vuxml/vuln.xml,v (\d+\.\d+) (\d\d\d\d/\d\d/\d\d) (\d\d:\d\d:\d\d) (\S+) (\S+) .*$#;
		$ident{Revision}  = $1;
		$ident{Date}      = $2;
		$ident{Time}      = $3;
		$ident{Committer} = $4;
	}

	return %ident;
}

sub usage {
	print "USAGE : $0 INPUTFILE\n";
}


my %ident;
my $vulnfile;


if (($#ARGV+1) == 1) {
	$vulnfile = $ARGV[0];
} else {
	usage();
	exit 1;
}
	

%ident = vuln_ident($vulnfile);

if (%ident) {
	print("Revision:  $ident{Revision}\n");
	print("Date:      $ident{Date}\n");
	print("Time:      $ident{Time}\n");
	print("Committer: $ident{Committer}\n");
} else {
	print "nothing found there\n";
}
