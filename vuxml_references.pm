#!/usr/bin/perl
#
# $Id: vuxml_references.pm,v 1.1.2.3 2004-12-11 00:58:31 dan Exp $
#
# Copyright (c) 2004 DVL Software
#

package FreshPorts::vuxml_references;

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
	my $this = shift;
}

sub _GetValuesFromRow {
	my $this = shift;
	my $row  = shift;

	$this->{id}         = $row->{id};
	$this->{vuxml_id}   = $row->{vuxml_id};
	$this->{type}       = $row->{type};
	$this->{reference}  = $row->{reference};
}

sub save {
	my $this = shift;

	my $dbh = $this->{dbh}; # just a short cut...
	my $sth;
	my $sql;
	my @row;

	if (!defined($this->{id})) {
		$this->{id} = FreshPorts::Database::GetNextValue($FreshPorts::Constants::vuxml_references_seq, $dbh);

		$sql = "insert into vuxml_references(id, vuxml_id, type, reference) values (
				$this->{id},
				" . $this->{vuxml_id}  . ",
				" . $dbh->quote($this->{type})      . ",
				" . $dbh->quote($this->{reference}) . ")";
	} else {
		$sql = "UPDATE vuxml_references
				   SET vuxml_id  = " . $this->{vuxml_id}  . ",
				       type      = " . $dbh->quote($this->{type})      . ",
				       reference = " . $dbh->quote($this->{reference}) . "
				 WHERE id        = " . $this->{id};
	}

	print "sql is $sql\n";

	$sth = $this->{dbh}->prepare($sql);
	if (!$sth->execute) {
		FreshPorts::Utilities::ReportError('warning', "Could not execute SQL $sql ... maybe invalid? " . $dbh->errstr, 1);
	}

	# after saving, return the ID
	return $this->{id};
}

1;