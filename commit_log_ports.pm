#!/usr/local/bin/perl -w
#
# $Id: commit_log_ports.pm,v 1.10 2006-12-17 12:03:59 dan Exp $
#
# Copyright (c) 2001-2003 DVL Software
#

package FreshPorts::CommitLogPorts;

use strict;
use FreshPorts::utilities;

sub new {
	my $this     = {};
	my $class    = shift;

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

	my $quoted_port_version	 = $dbh->quote($this->{port_version});
	my $quoted_port_revision = $dbh->quote($this->{port_revision});
	my $quoted_port_epoch	 = $dbh->quote($this->{port_epoch});

	if (!defined($this->{saved})) {
		# we are inserting
		$sql = "insert into commit_log_ports
				(commit_log_id, port_id, needs_refresh, port_version, port_revision, port_name_revision) values
				($this->{commit_log_id}, $this->{port_id}, $this->{needs_refresh},
				 $quoted_port_version, $quoted_port_revision, PackageName($this->{port_id}) || '-' || $quoted_port_version)";
	} else {
		# we are updating
		$sql = "update commit_log_ports
				   set needs_refresh  =  $this->{needs_refresh},
					    port_version  = $quoted_port_version,
					    port_revision = $quoted_port_revision,
					    port_epoch    = $quoted_port_epoch,
					    port_name_revision = PackageName($this->{port_id}) || '-' || $quoted_port_version
				 where commit_log_id = $this->{commit_log_id}
				   and port_id       = $this->{port_id}";
	}

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

1;
