#!/usr/bin/perl
#
# $Id: vuxml_ranges.pm,v 1.1.2.2 2004-09-11 14:03:43 dan Exp $
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

	$this->{id}                   = $row->{id};
	$this->{vuxml_name_id}        = $row->{vuxml_name_id};
	$this->{range_operator_start} = $row->{range_operator_start};
	$this->{range_operator_end}   = $row->{range_operator_end};
	$this->{range_version_start}  = $row->{range_version_start};
	$this->{range_version_end}    = $row->{range_version_end};
}

sub save {
	my $this = shift;

	my $dbh = $this->{dbh}; # just a short cut...
	my $sth;
	my $sql;
	my @row;

	$this->{id} = FreshPorts::Database::GetNextValue($FreshPorts::Constants::vuxml_ranges_seq, $dbh);

	$sql = "insert into vuxml_ranges(id, vuxml_name_id, range_operator_start, range_operator_end, 
					range_version_start, range_version_end) values (
				$this->{id},
				" . $dbh->quote($this->{vuxml_name_id})        . ",
				" . $dbh->quote($this->{range_operator_start}) . ",
				" . $dbh->quote($this->{range_operator_end})   . ",
				" . $dbh->quote($this->{range_version_start})  . ",
				" . $dbh->quote($this->{range_version_end})    . ")";

	print "sql is $sql\n";

	$sth = $this->{dbh}->prepare($sql);
	if (!$sth->execute) {
		FreshPorts::Utilities::ReportError('warning', "Could not execute SQL $sql ... maybe invalid? " . $dbh->errstr, 1);
	}

	# after saving, return the ID
	return $this->{id};
}

1;