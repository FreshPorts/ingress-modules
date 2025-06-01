#!/usr/local/bin/perl -w
#
# $Id: commit_log_ports_elements.pm,v 1.2 2006-12-17 12:03:59 dan Exp $
#
# Copyright (c) 2003 DVL Software
#

package FreshPorts::CommitLogPortsElements;

use strict;
use FreshPorts::utilities;

sub new {
	my $this  = {};
	my $class = shift;

	$this->{dbh} = shift;

	bless $this;

	$this->_initialize();

	return $this
}

sub _initialize {
	#
	# a value of -1 means that the refresh requirements have
	# not yet been established.
	# essentially, this is a newly added port.  some ports
	# are slave ports.  querying the Makefile will provide
	# the locations of the master port files required to
	# refresh this port.
	#
	my $this = shift;
	$this->{needs_refresh} = -1;
}

sub save {
	my $this = shift;

	my $dbh = $this->{dbh}; # just a short cut...
	my $sth;
	my $sql;
	my @row;

	$sql = "insert into commit_log_ports_elements
				(commit_log_id, element_id) values
				($this->{commit_log_id}, $this->{element_id})";

	print "sql is $sql\n";

	$sth = $this->{dbh}->prepare($sql);
	if (!$sth->execute) {
		FreshPorts::Utilities::ReportError('warning', "Could not execute SQL $sql ... maybe invalid? ". $dbh->errstr, 1);
	}

	$sth->finish();

	#
	# This is the only way we know we've save this already.  we don't have an id.
	# we could query the db for our primary key, but perhaps we don't have to.
	#
	$this->{saved} = 1;
}

sub DESTROY {
	my $this = shift;

	undef $this->{dbh};
}

1;
