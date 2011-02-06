#!/usr/bin/perl
#
# $Id: port_dependencies.pm,v 1.1 2011-02-06 14:54:43 dan Exp $
#
# Copyright (c) 2001-2011 DVL Software
#

package FreshPorts::PortDependencies;

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

sub insert {
	my $this = shift;
	

	my $dbh = $this->{dbh}; # just a short cut...
	my $sth;
	my $sql;
	
	my $quoted_port_name           = $dbh->quote($this->{port_name});
	my $quoted_port_name_dependant = $dbh->quote($this->{port_name_dependant});
	my $quoted_dependency_type     = $dbh->quote($this->{depends_type});

	# we are inserting
	$sql = "SELECT PortsDependenciesAdd( $quoted_port_name, $quoted_port_name_dependant, $quoted_dependency_type )";

	print "sql is $sql\n";

	$sth = $this->{dbh}->prepare($sql);
	if (!$sth->execute) {
		FreshPorts::Utilities::ReportError('warning', "Could not execute SQL $sql ... maybe invalid? ". $dbh->errstr, 1);
	}
}

sub delete {
	my $this = shift;

	my $dbh = $this->{dbh}; # just a short cut...
	my $sth;
	my $sql;
	
	# we are deleting all
	$sql = 'DELETE FROM port_dependencies WHERE port_id = ' . $this->{port_id};

	print "sql is $sql\n";

	$sth = $this->{dbh}->prepare($sql);
	if (!$sth->execute) {
		FreshPorts::Utilities::ReportError('warning', "Could not execute SQL $sql ... maybe invalid? ". $dbh->errstr, 1);
	}
}

1;
