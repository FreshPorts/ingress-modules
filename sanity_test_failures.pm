#!/usr/local/bin/perl
#
# $Id: sanity_test_failures.pm,v 1.2 2006-12-17 12:04:03 dan Exp $
#
# Copyright (c) 2001-2006 DVL Software
#

package FreshPorts::SanityTestFailures;

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
}

sub SetCommitLogID($) {
	my $this        = shift;
	my $CommitLogID = shift;
	
	$this->{commit_log_id} = $CommitLogID;
}

sub SetErrorText($) {
	my $this      = shift;
	my $ErrorText = shift;
	
	$this->{message} = $ErrorText;
}

sub Save($) {
	my $this = shift;

	my $dbh = $this->{dbh}; # just a short cut...
	my $sth;
	my $sql;
	my @row;

	$this->{id} = FreshPorts::Database::GetNextValue($FreshPorts::Constants::sanity_test_failures_seq, $dbh);

	my $QuotedMsg = $dbh->quote($this->{message});
	$sql = "insert into sanity_test_failures (id, commit_log_id, message) values ( \
				$this->{id}, \
				$this->{commit_log_id}, \ 
				$QuotedMsg)";
	print "sql is $sql\n";

	$sth = $this->{dbh}->prepare($sql);
	if (!$sth->execute) {
		FreshPorts::Utilities::ReportError('warning', "Could not execute SQL $sql ... maybe invalid? " . $dbh->errstr, 1);
	}

	# after saving, return the ID
	return $this->{id};
}

1;
