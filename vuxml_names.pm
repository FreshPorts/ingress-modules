#!/usr/bin/perl
#
# $Id: vuxml_names.pm,v 1.1.2.8 2004-12-14 00:43:47 dan Exp $
#
# Copyright (c) 2004 DVL Software
#

package FreshPorts::vuxml_names;

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

	$this->{id}                = $row->{id};
	$this->{vuxml_affected_id} = $row->{vuxml_affected_id};
	$this->{name}              = $row->{name};
}

sub empty {
	my $this = shift;
	my $row  = shift;

	$this->{id}                = undef;
	$this->{vuxml_affected_id} = undef;
	$this->{name}              = undef;
}

sub save {
	my $this = shift;

	my $dbh = $this->{dbh}; # just a short cut...
	my $sth;
	my $sql;
	my @row;

	if (!defined($this->{id})) {
		$this->{id} = FreshPorts::Database::GetNextValue($FreshPorts::Constants::vuxml_names_seq, $dbh);

		$sql = "insert into vuxml_names(id, vuxml_affected_id, name) values (
				$this->{id},
				$this->{vuxml_affected_id},
				" . $dbh->quote($this->{name}) . ')';
	} else {
		$sql = "UPDATE vuxml_names
				   SET vuxml_affected_id = " . $this->{vuxml_affected_id} . ",
				       name              = " . $dbh->quote($this->{name}) . "
				 WHERE id                = " . $this->{id}                . "
              ORDER BY id";
	}

#	print "sql is $sql\n";

	$sth = $this->{dbh}->prepare($sql);
	if (!$sth->execute) {
		FreshPorts::Utilities::ReportError('warning', "Could not execute SQL $sql ... maybe invalid? " . $dbh->errstr, 1);
	}

	# after saving, return the ID
	return $this->{id};
}

sub FetchByVuXMLAffectedID {
	my $this              = shift;
	my $vuxml_affected_id = shift;

	my $dbh;
	my $sql;
	my $sth;
	my $row;

	my @Names;
	my $vuxml_names;

	$dbh = $this->{dbh};

	$sql = "SELECT vuxml_names.*
              FROM vuxml_names
             WHERE vuxml_names.vuxml_affected_id = $vuxml_affected_id";

#	print "sql = '$sql'\n";

	$sth = $dbh->prepare($sql);
	if (!$sth->execute) {
		FreshPorts::Utilities::ReportError('warning', "Could not execute SQL $sql", 1);
	}

	while ($row = $sth->fetchrow_hashref()) {
		$vuxml_names = FreshPorts::vuxml_names->new( $this->{dbh} );

#		print "vuxml_names.pm:111 reading " . $vuxml_names->{id} . "\n";

		$vuxml_names->set_id               ($row->{id});
		$vuxml_names->set_vuxml_affected_id($row->{vuxml_affected_id});
		$vuxml_names->set_name             ($row->{name});

		push @Names, $vuxml_names;
	}
	$sth->finish();

	return @Names;
}

sub set_id {
	my $this = shift;
	my $id   = shift;

	$this->{id} = $id;

	return $this->{id};
}

sub set_vuxml_affected_id {
	my $this              = shift;
	my $vuxml_affected_id = shift;

	$this->{vuxml_affected_id} = $vuxml_affected_id;

	return $this->{vuxml_affected_id};
}

sub set_name {
	my $this = shift;
	my $name = shift;

	$this->{name} = $name;

	return $this->{name};
}

sub print {
	my $this = shift;

	print "\n   vuxml_names.pm:150\n";

	print "   id                = '" . $this->{id}                . "'\n";
	print "   vuxml_affected_id = '" . $this->{vuxml_affected_id} . "'\n";
	print "   name              = '" . $this->{name}              . "'\n";
}

1;
