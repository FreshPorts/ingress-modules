#!/usr/local/bin/perl -w
#
# Copyright (c) 2014-2026 Dan Langille
#

package FreshPorts::Commit_Log_Branches;

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
    my $this = shift;
}

sub save {
	my $this = shift;

	my $dbh = $this->{dbh}; # just a short cut...
	my $sth;
	my $sql;
	my @row;

	$sql = 'SELECT CommitLogBranchesInsert(' . $this->{commit_log_id} . ', ' . $this->{branch_id} . ')';

	print "sql is $sql\n";

	$sth = $this->{dbh}->prepare($sql);
	if (!$sth->execute) {
		FreshPorts::Utilities::ReportError('warning', "Could not execute SQL $sql ... maybe invalid? ". $dbh->errstr, 1);
	}

	$sth->finish();
}

1;
