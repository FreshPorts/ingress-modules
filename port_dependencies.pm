#!/usr/local/bin/perl -w
#
# $Id: port_dependencies.pm,v 1.2 2011-08-15 16:32:47 dan Exp $
#
# Copyright (c) 2001-2011 DVL Software
#

package FreshPorts::PortDependencies;

use strict;
use FreshPorts::utilities;

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
	my $quoted_port_name_dependent = $dbh->quote($this->{port_name_dependent});
	my $quoted_dependency_type     = $dbh->quote($this->{depends_type});

	# we are inserting
	$sql = "SELECT PortsDependenciesAdd( $quoted_port_name, $quoted_port_name_dependent, $quoted_dependency_type ) as result";

	print "sql is $sql\n";

	$sth = $this->{dbh}->prepare($sql);
  if ($sth->execute)
  {
    my $row = $sth->fetchrow_hashref();
    my $result = $row->{result};
    print "result is $result\n";
    return $result;
  }
  else
  {
    FreshPorts::Utilities::ReportError('warning', "Could not execute SQL $sql ... maybe invalid? ". $dbh->errstr, 0);
    print "that failed\n";
    return 0;
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
