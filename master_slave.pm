#!/usr/local/bin/perl -w
#
# $Id: master_slave.pm,v 1.2 2006-12-17 12:04:01 dan Exp $
#
# Copyright (c) 2004-2026 Dan Langille
#

package FreshPorts::MasterSlave;

use strict;

sub _initialize {
	my $this = shift;

	$this->{slave_port_name}   = '';
	$this->{slave_category}    = '';
}

sub new {
	my $this		= {};
	my $class		= shift;

	$this->{dbh}	= shift;

	bless $this;
	$this->_initialize();
	return $this;
}


sub _GetValuesFromRow {
	my $this = shift;
	my $row  = shift;

	$this->{slave_port_name}     = $row->{slave_port_name};
	$this->{slave_category_name} = $row->{slave_category_name};
}

sub FetchByMaster($) {
	my $this = shift;
	
	my $sql;
	my $sth;
	my $row;
	my %Slaves;

	my $dbh = $this->{dbh};

	my $MasterPort = shift;
	# As of 2022-12-10, ports_active is head only
	# we can remove the element_pathname references
	$sql = "
SELECT PA.name        AS slave_port_name,
       PA.category    AS slave_category_name
       FROM ports_active PA JOIN element_pathname EP ON PA.element_id = EP.element_id
 WHERE PA.master_port = " . $dbh->quote($MasterPort) . "
ORDER BY slave_category_name, slave_port_name";

#	echo "sql = <pre>$sql</pre>";

	$sth = $dbh->prepare($sql);
	if ( !defined $sth ) {
		FreshPorts::Utilities::ReportError('warning', "Could not prepare SQL $sql" . pg_last_error(), 1);
	}

	if (!$sth->execute) {
		FreshPorts::Utilities::ReportError('warning', "Could not execute SQL $sql" . pg_last_error(), 1);
	}

	while ($row = $sth->fetchrow_hashref()) {
		$this->_GetValuesFromRow($row);
		$Slaves{"$this->{slave_category_name}/$this->{slave_port_name}"} = 1;
	}

	$sth->finish();

	return %Slaves;
}

1;
