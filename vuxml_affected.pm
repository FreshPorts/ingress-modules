#!/usr/bin/perl
#
# $Id: vuxml_affected.pm,v 1.1.2.1 2004-09-10 03:26:41 dan Exp $
#
# Copyright (c) 2004 DVL Software
#

package FreshPorts::vuxml_affected;

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
	my $row  = shift;

	$this->{encoding_losses} = 0;
}

sub _GetValuesFromRow {
	my $this = shift;
	my $row  = shift;

	$this->{id} 		= $row->{id};
	$this->{vuxml_id}	= $row->{vuxml_id};
	$this->{type}		= $row->{type};
}

sub save {
	my $this = shift;

	my $dbh = $this->{dbh}; # just a short cut...
	my $sth;
	my $sql;
	my @row;

	$this->{id} = FreshPorts::Database::GetNextValue($FreshPorts::Constants::vuxml_affected_seq, $dbh);

	$sql = "insert into vuxml_affected(id, vuxml_id, type, date_modified) values (
				$this->{id},
				$this->{vuxml_id},
				" . $dbh->quote($this->{type}) . ')';

	print "sql is $sql\n";

	$sth = $this->{dbh}->prepare($sql);
	if (!$sth->execute) {
		FreshPorts::Utilities::ReportError('warning', "Could not execute SQL $sql ... maybe invalid? " . $dbh->errstr, 1);
	}

	# after saving, return the ID
	return $this->{id};
}

1;