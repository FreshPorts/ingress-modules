#!/usr/bin/perl
#
# $Id: commit_log_ports.pm,v 1.4 2001-12-22 21:48:55 dan Exp $
#
# Copyright (c) 2001 DVL Software
#

package FreshPorts::CommitLogPorts;

use strict;


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

sub save {
	my $this = shift;

	my $dbh = $this->{dbh}; # just a short cut...
	my $sth;
	my $sql;
	my @row;

	# we are inserting
	$sql = "insert into commit_log_ports (commit_log_id, port_id) values \
				($this->{commit_log_id}, $this->{port_id})";

	print "sql is $sql\n";

	$sth = $this->{dbh}->prepare($sql);
	if (!$sth->execute) {
		Sys::Syslog::syslog('warning', "Could not execute SQL $sql ... maybe invalid? ". $dbh->errstr);
		die "Could not execute SQL $sql ... maybe invalid? ". $dbh->errstr;
	}
}

1;