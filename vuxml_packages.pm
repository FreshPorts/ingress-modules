#!/usr/bin/perl
#
# $Id: vuxml_packages.pm,v 1.1.2.1 2004-12-11 15:28:03 dan Exp $
#
# Copyright (c) 2004 DVL Software
#

package FreshPorts::vuxml_packages;

use strict;
use utilities;
use constants;

use vuxml_affected;
use vuxml_names;
use vuxml_ranges;

sub new {
	my $this		= {};
	my $class		= shift;
	$this->{dbh}	= shift;

	bless $this;

	$this->_initialize();

	return $this
}

sub _initialize {
	my $this = shift;
}

sub FetchPackageDetails {
	my $this = shift;
	my $VID  = shift;

	my @Packages;

	my $vuxml_affected = FreshPorts::vuxml_affected->new( $this->{dbh} );

	@Packages = $vuxml_affected->FetchByVID($VID);
	foreach my $Package (@Packages) {
		print " id = '"       . $Package->{id}       . "'";
		print " vuxml_id = '" . $Package->{vuxml_id} . "'";
		print " type = '"     . $Package->{type}     . "'";
		print "\n";
	}


} 


1;