#!/usr/bin/perl
#
# $Id: vuxml_affected.pm,v 1.1.2.5 2004-12-11 15:27:02 dan Exp $
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

	if (!defined($this->{id})) {
	
		$this->{id} = FreshPorts::Database::GetNextValue($FreshPorts::Constants::vuxml_affected_seq, $dbh);

		$sql = "insert into vuxml_affected(id, vuxml_id, type) values (
				$this->{id},
				$this->{vuxml_id},
				" . $dbh->quote($this->{type}) . ')';
	} else {
		$sql = "
UPDATE vuxml_affected
   SET vuxml_id = "  .  $this->{vuxml_id} . ",
       type     = '" . $dbh->quote($this->{type}) . "
 WHERE id       = "  . $this->{id};
	}


	print "sql is $sql\n";

	$sth = $this->{dbh}->prepare($sql);
	if (!$sth->execute) {
		FreshPorts::Utilities::ReportError('warning', "Could not execute SQL $sql ... maybe invalid? " . $dbh->errstr, 1);
	}

	# after saving, return the ID
	return $this->{id};
}

sub FetchByVID {
	my $this = shift;
	my $VID  = shift;

	my $dbh;
	my $sql;
	my $sth;
	my $row;

	my @Affected;

	$dbh = $this->{dbh};

	$sql = "SELECT vuxml_affected.*
              FROM vuxml_affected, vuxml
             WHERE vuxml_affected.vuxml_id = vuxml.id
               AND vuxml.vid = " .  $dbh->quote($VID);

	print "sql = '$sql'\n";

	$sth = $dbh->prepare($sql);
	if (!$sth->execute) {
		FreshPorts::Utilities::ReportError('warning', "Could not execute SQL $sql", 1);
	}

	while ($row = $sth->fetchrow_hashref()) {
		push @Affected, $row;
	}
	$sth->finish();

	return @Affected;
}

1;