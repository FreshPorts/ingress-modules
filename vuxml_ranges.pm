#!/usr/bin/perl
#
# $Id: vuxml_ranges.pm,v 1.1.2.4 2004-09-20 19:55:32 dan Exp $
#
# Copyright (c) 2004 DVL Software
#

package FreshPorts::vuxml_ranges;

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
}

sub _GetValuesFromRow {
	my $this = shift;
	my $row  = shift;

	$this->{id}                = $row->{id};
	$this->{vuxml_affected_id} = $row->{vuxml_affected_id};
	$this->{operator1}         = $row->{operator1};
	$this->{operator2}         = $row->{operator2};
	$this->{version1}          = $row->{version1};
	$this->{version2}          = $row->{version2};
}

sub save {
	my $this = shift;

	my $dbh = $this->{dbh}; # just a short cut...
	my $sth;
	my $sql;
	my @row;

	$this->{id} = FreshPorts::Database::GetNextValue($FreshPorts::Constants::vuxml_ranges_seq, $dbh);

	$sql = "insert into vuxml_ranges(vuxml_affected_id, version1, operator1,
					operator2, version2) values (
				" . $this->{vuxml_affected_id}      . ",
				" . $dbh->quote($this->{version1})  . ",
				" . $dbh->quote($this->{operator1}) . ",
				" . $dbh->quote($this->{operator2}) . ",
				" . $dbh->quote($this->{version2})  . ")";

	print "sql is $sql\n";

	$sth = $this->{dbh}->prepare($sql);
	if (!$sth->execute) {
		FreshPorts::Utilities::ReportError('warning', "Could not execute SQL $sql ... maybe invalid? " . $dbh->errstr, 1);
	}

	# after saving, return the ID
	return $this->{id};
}

1;