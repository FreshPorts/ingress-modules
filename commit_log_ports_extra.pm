#!/usr/bin/perl
#
# $Id: commit_log_ports_extra.pm,v 1.1.2.1 2003-10-04 21:06:11 dan Exp $
#
# Copyright (c) 2003 DVL Software
#

package FreshPorts::CommitLogPortsExtra;

use strict;
use utilities;

sub new {
	my $this		= {};
	my $class		= shift;

	$this->{dbh}	= shift;

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

	$sql = "insert into commit_log_ports_extra
				(commit_log_id, element_id) values
				($this->{commit_log_id}, $this->{element_id})";

	print "sql is $sql\n";

	$sth = $this->{dbh}->prepare($sql);
	if (!$sth->execute) {
		FreshPorts::Utilities::ReportError('warning', "Could not execute SQL $sql ... maybe invalid? ". $dbh->errstr, 1);
	}

	#
	# This is the only way we know we've save this already.  we don't have an id.
	# we could query the db for our primary key, but perhaps we don't have to.
	#
	$this->{saved} = 1;
}

1;