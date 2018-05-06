#!/usr/local/bin/perl
#
# $Id: vuxml_package.pm,v 1.2 2006-12-17 12:04:04 dan Exp $
#
# Copyright (c) 2004 DVL Software
#

package FreshPorts::vuxml_package;

use strict;
use FreshPorts::utilities;

use FreshPorts::vuxml_affected;
use FreshPorts::vuxml_names;
use FreshPorts::vuxml_ranges;

my @Packages;


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

	$this->{names}  = ();
	$this->{ranges} = ();
}

sub Fetch {
	my $this = shift;
	my $VID  = shift;

	$this->FetchPackages($VID);

	$this->FetchPackageNames();
	$this->FetchPackageRanges();

	return $VID;
}

sub FetchByVID {
	my $this = shift;
	my $VID  = shift;

	my $vuxml_package = undef;


	my $vuxml_affected = FreshPorts::vuxml_affected->new( $this->{dbh} );
#	print "checking universal vuxml_package.pm:57'" . UNIVERSAL::isa($vuxml_affected, "FreshPorts::vuxml_affected") . "'\n";

	@Packages = $vuxml_affected->FetchByVID($VID);

#	print "first loop\n";
	foreach my $package (@Packages) {
#		print $package->{id} . "\n";
#		print "checking universal vuxml_package.pm:64 '" . UNIVERSAL::isa($package, "FreshPorts::vuxml_package") . "'\n";
		$package->FetchNames ($package->{id});
		$package->FetchRanges($package->{id});
	}

	return @Packages;
}

sub FetchNames {
	my $this              = shift;
	my $vuxml_affected_id = shift;

	my @Names;
	my $vuxml_names = FreshPorts::vuxml_names->new( $this->{dbh} );

	@Names = $vuxml_names->FetchByVuXMLAffectedID($vuxml_affected_id);

#	foreach my $name (@Names) {
#		$name->print();
#	}

	$this->{names} = \@Names;
#	foreach my $name (@{$this->{names}}) {
#		$name->print();
#	}
}

sub FetchRanges {
	my $this              = shift;
	my $vuxml_affected_id = shift;

	my @Ranges;
	my $vuxml_ranges = FreshPorts::vuxml_ranges->new( $this->{dbh} );

	@Ranges = $vuxml_ranges->FetchByVuXMLAffectedID($vuxml_affected_id);
	$this->{ranges} = \@Ranges;
}

sub set_id {
	my $this = shift;
	my $id   = shift;

	$this->{id} = $id;

	return $this->{id};
}

sub set_vuxml_id {
	my $this     = shift;
	my $vuxml_id = shift;

	$this->{vuxml_id} = $vuxml_id;

	return $this->{vuxml_id};
}

sub set_type {
	my $this = shift;
	my $type = shift;

	$this->{type} = $type;

	return $this->{type};
}

sub print {
	my $this = shift;

	print "vuxml_package.pm:124\n";

	print "   id       = '" . $this->{id}       . "'\n";
	print "   vuxml_id = '" . $this->{vuxml_id} . "'\n";
	print "   type     = '" . $this->{type}     . "'\n";

	foreach my $name (@{$this->{names}}) {
		$name->print();
	}

	foreach my $range (@{$this->{ranges}}) {
		$range->print();
	}

	
}

1;
