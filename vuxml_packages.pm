#!/usr/local/bin/perl -w
#
# $Id: vuxml_packages.pm,v 1.2 2006-12-17 12:04:05 dan Exp $
#
# Copyright (c) 2004-2026 Dan Langille
#

package FreshPorts::vuxml_packages;

use strict;
use FreshPorts::utilities;
use FreshPorts::constants;

use FreshPorts::vuxml_affected;
use FreshPorts::vuxml_names;
use FreshPorts::vuxml_ranges;
use FreshPorts::vuxml_package;

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

	$this->{packages} = undef;
}

sub Fetch {
	my $this = shift;
	my $VID  = shift;

	$this->FetchPackages($VID);

	$this->FetchPackageNames();
	$this->FetchPackageRanges();

	return $VID;
}

sub FetchPackages {
	my $this = shift;
	my $VID  = shift;

	my $vuxml_package = undef;

	my @Affected;

	my $vuxml_affected = FreshPorts::vuxml_affected->new( $this->{dbh} );

	@Affected = $vuxml_affected->FetchByVID($VID);

	print "first loop\n";
	foreach my $affected (@Affected) {
		print $affected->{id} . "\n";
	}

	$this->{affected} = \@Affected;

	print "second loop\n";
	foreach my $affected (@{$this->{affected}}) {
		print $affected->{id} . "\n";
	}

	return $VID;
}

sub FetchPackageNames {
	my $this = shift;

	foreach my $affected (@{$this->{affected}}) {
		print $affected . "\n";
		$affected->fetch_names();
	}
}

sub FetchPackageRanges {
	my $this = shift;

	# for each affected, fetch the names

	foreach my $affected ($this->{affected}) {
		$affected->fetch_ranges();
	}

} 

1;
