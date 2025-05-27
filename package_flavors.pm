#!/usr/local/bin/perl -w
#
# $Id: commit_log_port_elements.pm,v 1.4 2006-12-17 12:03:59 dan Exp $
#
# Copyright (c) 2001-2003 DVL Software
#

package FreshPorts::PackageFlavors;

use strict;
use FreshPorts::utilities;

sub new {
	my $this		= {};
	my $class		= shift;
	$this->{dbh}	= shift;
	bless $this;
	$this->_initialize();
	return $this
}

sub _initialize {
}

sub delete {
	my $this = shift;

	my $dbh = $this->{dbh}; # just a short cut...
	my $sth;
	my $sql;
	my @row;
	
	# delete all the package flavors for a given port
	$sql = "select PackageFlavorsDelete($this->{port_id})";
	print "sql is $sql\n";

	$sth = $this->{dbh}->prepare($sql);
	if (!$sth->execute) {
		FreshPorts::Utilities::ReportError('warning', "Could not execute SQL $sql ... maybe invalid? ". $dbh->errstr, 1);
	}
	$sth->finish();
}

sub add {
	my $this = shift;

	my $dbh = $this->{dbh}; # just a short cut...
	my $sth;
	my $sql;
	my @row;
	
	my $quoted_flavor      = $dbh->quote($this->{flavor});      # e.g. py27
	my $quoted_flavor_name = $dbh->quote($this->{flavor_name}); # e.g. py27-requests-kerberos

	# insert a new package flavor
	$sql = "select PackageFlavorAdd($this->{port_id}, $quoted_flavor, $quoted_flavor_name, $this->{flavor_number})";
	print "sql is $sql\n";

	$sth = $this->{dbh}->prepare($sql);
	if (!$sth->execute) {
		FreshPorts::Utilities::ReportError('warning', "Could not execute SQL $sql ... maybe invalid? ". $dbh->errstr, 1);
	}
	$sth->finish();
}

1;
