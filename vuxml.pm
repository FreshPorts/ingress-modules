#!/usr/bin/perl
#
# $Id: vuxml.pm,v 1.1.2.6 2004-12-12 15:46:50 dan Exp $
#
# Copyright (c) 2004 DVL Software
#

package FreshPorts::vuxml;

use strict;
use utilities;
use constants;

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

	$this->{id}             = $row->{id};
	$this->{vid}            = $row->{vid};
	$this->{topic}          = $row->{topic};
	$this->{description}    = $row->{description};
	$this->{date_discovery} = $row->{date_discovery};
	$this->{date_entry}     = $row->{date_entry};
	$this->{date_modified}  = $row->{date_modified};
	$this->{status}         = $row->{status};
}

sub empty {
	my $this = shift;

	$this->{id}             = undef;
	$this->{vid}            = undef;
	$this->{topic}          = undef;
	$this->{description}    = undef;
	$this->{date_discovery} = undef;
	$this->{date_entry}     = undef;
	$this->{date_modified}  = undef;
	$this->{status}         = undef;
}
sub save {
	my $this = shift;

	my $dbh = $this->{dbh}; # just a short cut...
	my $sth;
	my $sql;
	my @row;

	if (!defined($this->{id})) {
		$this->{id} = FreshPorts::Database::GetNextValue($FreshPorts::Constants::vuxml_seq, $dbh);

		$sql = "insert into vuxml(id, vid, topic, description, date_discovery, 
                               date_entry, date_modified, status) values (
				$this->{id},
				" . $dbh->quote($this->{vid})            . ",
				" . $dbh->quote($this->{topic})          . ",
				" . $dbh->quote($this->{description})    . ",
				" . $dbh->quote($this->{date_discovery}) . ",
				" . $dbh->quote($this->{date_entry})     . ",
				" . $dbh->quote($this->{date_modified})  . ",
                'A')";
	} else {
		$sql = "UPDATE vuxml SET
				vid            = " . $dbh->quote($this->{vid})            . ",
				topic          = " . $dbh->quote($this->{topic})          . ",
				description    = " . $dbh->quote($this->{description})    . ",
				date_discovery = " . $dbh->quote($this->{date_discovery}) . ",
				date_entry     = " . $dbh->quote($this->{date_entry})     . ",
				date_modified  = " . $dbh->quote($this->{date_modified})  . ",
                status         = " . $dbh->quote($this->{status})         . "
                WHERE id       = $this->{id}";
	}

	print "sql is $sql\n";

	$sth = $this->{dbh}->prepare($sql);
	if (!$sth->execute) {
		FreshPorts::Utilities::ReportError('warning', "Could not execute SQL $sql ... maybe invalid? " . $dbh->errstr, 1);
	}

	# after saving, return the ID
	return $this->{id};
}

sub FetchByID {
	my $this = shift;

	my $dbh;
	my $sql;
	my $sth;
	my $row;

	$dbh = $this->{dbh};

	$sql = "select vuxml.*
              from vuxml
             where vuxml.id = $this->{id}";

	print "sql = '$sql'\n";

	$sth = $dbh->prepare($sql);
	if (!$sth->execute) {
		FreshPorts::Utilities::ReportError('warning', "Could not execute SQL $sql", 1);
	}

	$row = $sth->fetchrow_hashref();
	$sth->finish();

	# no sense setting values if we didn't get anything...
	if ($row) {
		$this->_GetValuesFromRow($row);
	}

	return $this->{id};
}

sub FetchByVID {
	my $this = shift;

	my $dbh;
	my $sql;
	my $sth;
	my $row;

	$dbh = $this->{dbh};

	$sql = "select vuxml.*
              from vuxml
             where vuxml.vid = '$this->{vid}'";

	print "sql = '$sql'\n";

	$sth = $dbh->prepare($sql);
	if (!$sth->execute) {
		FreshPorts::Utilities::ReportError('warning', "Could not execute SQL $sql", 1);
	}

	$row = $sth->fetchrow_hashref();
	$sth->finish();

	# no sense setting values if we didn't get anything...
	if ($row) {
		$this->_GetValuesFromRow($row);
	} else {
		undef $this->{vid};
	}

	return $this->{vid};
}


1;