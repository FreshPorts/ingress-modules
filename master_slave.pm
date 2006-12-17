#
# $Id: master_slave.pm,v 1.2 2006-12-17 12:04:01 dan Exp $
#
# Copyright (c) 2004 DVL Software
#

package FreshPorts::MasterSlave;

use strict;

sub _initialize {
	my $this = shift;

	$this->{slave_port_id}     = '';
	$this->{slave_port_name}   = '';
	$this->{slave_category_id} = '';
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

	$this->{slave_port_id}			= $row->{slave_port_id};
	$this->{slave_port_name}		= $row->{slave_port_name};
	$this->{slave_category_id}		= $row->{slave_category_id};
	$this->{slave_category_name}	= $row->{slave_category_name};
}

sub FetchByMaster($) {
	my $this = shift;
	
	my $sql;
	my $sth;
	my $row;
	my %Slaves;

	my $dbh = $this->{dbh};

	my $MasterName = shift;
	$sql = "
SELECT id          AS slave_port_id,
       name        AS slave_port_name,
       category_id AS slave_category_id,
       category    AS slave_category_name
  FROM ports_active
 WHERE master_port = '$MasterName'
ORDER BY slave_category_name, slave_port_name";

#	echo "sql = <pre>$sql</pre>";

	$sth = $dbh->prepare($sql);
	if ( !defined $sth ) {
		FreshPorts::Utilities::ReportError('warning', "Could not prepare SQL $sql" . pg_lasterror(), 1);
	}

	if (!$sth->execute) {
		FreshPorts::Utilities::ReportError('warning', "Could not execute SQL $sql" . pg_lasterror(), 1);
	}

	while ($row = $sth->fetchrow_hashref()) {
		$this->_GetValuesFromRow($row);
		$Slaves{"$this->{slave_category_name}/$this->{slave_port_name}"} = 1;
	}

	return %Slaves;

}

1;
