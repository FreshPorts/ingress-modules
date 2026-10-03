#!/usr/local/bin/perl -w
#
# $Id: commit_log_ports_ignore.pm,v 1.2 2006-12-17 12:03:59 dan Exp $
#
# Copyright (c) 2001-2026 Dan Langille
#

package FreshPorts::PortsIgnoreRefresh;

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
	my $this = shift;
}

sub save {
	my $this = shift;

	my $dbh = $this->{dbh}; # just a short cut...
	my $sth;
	my $sql;
	my @row;

	my $quoted_reason = $dbh->quote($this->{reason});

	$sql = "insert into commit_log_ports_ignore
				(commit_log_id, port_id, reason) values
				($this->{commit_log_id}, $this->{port_id}, $quoted_reason)";

	print "sql is $sql\n";

	$sth = $this->{dbh}->prepare($sql);
	if (!$sth->execute) {
		FreshPorts::Utilities::ReportError('warning', "Could not execute SQL $sql ... maybe invalid? ". $dbh->errstr, 1);
	}

	$sth->finish();
}

sub delete {
	my $this = shift;

	my $dbh = $this->{dbh}; # just a short cut...
	my $sth;
	my $sql;
	my @row;

	my $quoted_reason = $dbh->quote($this->{reason});

	$sql = "delete from commit_log_ports_ignore
		      WHERE commit_log_id = this->{commit_log_id} and port_id = $this->{port_id}";

	print "sql is $sql\n";

	$sth = $this->{dbh}->prepare($sql);
	if (!$sth->execute) {
		FreshPorts::Utilities::ReportError('warning', "Could not execute SQL $sql ... maybe invalid? ". $dbh->errstr, 1);
	}

	$sth->finish();
}
1;
