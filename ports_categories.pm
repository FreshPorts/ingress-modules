#!/usr/bin/perl
#
# $Id: ports_categories.pm,v 1.1.2.2 2003-05-16 01:14:06 dan Exp $
#
# Copyright (c) 2001-2003 DVL Software
#

package FreshPorts::PortsCategories;

use strict;
use utilities;

sub new {
	my $this			= {};
	my $class		= shift;
	$this->{dbh}	= shift;
	bless $this;
	$this->_initialize();
	return $this
}

sub _initialize {
}

sub save {
	my $this = shift;

	my $dbh = $this->{dbh}; # just a short cut...
	my $sth;
	my $sql;
	my @row;

	# we are inserting
	$sql = "insert into ports_categories values ($this->{port_id}, $this->{category_id})";

#	print "sql is $sql\n";

	$sth = $this->{dbh}->prepare($sql);
	if (!$sth->execute) {
		FreshPorts::Utilities::ReportError('warning', "Could not execute SQL $sql ... maybe invalid? ". $dbh->errstr, 1);
	}
}

1;