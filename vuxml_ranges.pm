#!/usr/bin/perl
#
# $Id: vuxml_ranges.pm,v 1.2 2006-12-17 12:04:05 dan Exp $
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

sub empty {
	my $this = shift;

	$this->{id}                = undef;
	$this->{vuxml_affected_id} = undef;
	$this->{operator1}         = undef;
	$this->{operator2}         = undef;
	$this->{version1}          = undef;
	$this->{version2}          = undef;
}

sub save {
	my $this = shift;

	my $dbh = $this->{dbh}; # just a short cut...
	my $sth;
	my $sql;
	my @row;

	if (!defined($this->{id})) {
		$this->{id} = FreshPorts::Database::GetNextValue($FreshPorts::Constants::vuxml_ranges_seq, $dbh);

		$sql = "insert into vuxml_ranges(id, vuxml_affected_id, version1, operator1,
					operator2, version2) values (
                " . $this->{id}                     . ",
				" . $this->{vuxml_affected_id}      . ",
				" . $dbh->quote($this->{version1})  . ",
				" . $dbh->quote($this->{operator1}) . ",
				" . $dbh->quote($this->{operator2}) . ",
				" . $dbh->quote($this->{version2})  . ")";
	} else {
		$sql = "UPDATE vuxml_ranges
				   SET vuxml_affected_id = " . $this->{vuxml_affected_id}      . ",
				       version1          = " . $dbh->quote($this->{version1})  . ",
				       operator1         = " . $dbh->quote($this->{operator1}) . ",
				       operator2         = " . $dbh->quote($this->{operator2}) . ",
				       version2          = " . $dbh->quote($this->{version2})  . "
				 WHERE id                = " . $this->{id}                     . "
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

	my @Ranges;
	my $vuxml_ranges;

	$dbh = $this->{dbh};

	$sql = "SELECT vuxml_ranges.*
              FROM vuxml_ranges
             WHERE vuxml_ranges.vuxml_affected_id = $vuxml_affected_id";

#	print "sql = '$sql'\n";

	$sth = $dbh->prepare($sql);
	if (!$sth->execute) {
		FreshPorts::Utilities::ReportError('warning', "Could not execute SQL $sql", 1);
	}

	while ($row = $sth->fetchrow_hashref()) {
		$vuxml_ranges = FreshPorts::vuxml_ranges->new( $this->{dbh} );

		$vuxml_ranges->set_id               ($row->{id});
		$vuxml_ranges->set_vuxml_affected_id($row->{vuxml_affected_id});
		$vuxml_ranges->set_operator1        ($row->{operator1});
		$vuxml_ranges->set_version1         ($row->{version1});
		$vuxml_ranges->set_operator2        ($row->{operator2});
		$vuxml_ranges->set_version2         ($row->{version2});

		push @Ranges, $vuxml_ranges;
	}
	$sth->finish();

	return @Ranges;
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


sub set_operator1 {
	my $this      = shift;
	my $operator1 = shift;

	$this->{operator1} = $operator1;

	return $this->{operator1};
}


sub set_version1 {
	my $this     = shift;
	my $version1 = shift;

	$this->{version1} = $version1;

	return $this->{version1};
}

sub set_operator2 {
	my $this      = shift;
	my $operator2 = shift;

	$this->{operator2} = $operator2;

	return $this->{operator2};
}

sub set_version2 {
	my $this     = shift;
	my $version2 = shift;

	$this->{version2} = $version2;

	return $this->{version2};
}

sub print {
	my $this = shift;

	print "\n   vuxml_ranges.pm:150\n";

	print "   id                = '" . $this->{id}                . "'\n";
	print "   vuxml_affected_id = '" . $this->{vuxml_affected_id} . "'\n";
	print "   operator1         = '" . $this->{operator1}         . "'\n";
	print "   version1          = '" . $this->{version1}          . "'\n";
	print "   operator2         = '" . $this->{operator2}         . "'\n";
	print "   version2          = '" . $this->{version2}          . "'\n";
}

1;
