#!/usr/local/bin/perl -w
#
# Copyright (c) 2023 Dan Langille
#

package FreshPorts::Port_refresh;

use strict;
use FreshPorts::constants;
use FreshPorts::port;
use FreshPorts::utilities;
 
use DBI;

use FreshPorts::database;
use FreshPorts::utilities;

my $dbh;

my $maxlength=0;
my $dirname='';
my $porttorefresh;
my @PORTS;
my $sql;
my @row;


# =================================

sub _initialize {
}

# =================================

sub new {
	my $this	= {};
	my $class	= shift;
	$this->{dbh}	= shift;
	bless $this;
	$this->_initialize();
	return $this
}

sub refresh_one_port {
	my $this    = shift;
	my $port_id = shift;

	my $dbh = $this->{dbh}; # just a short cut...

	my $port = FreshPorts::Port->new($dbh);
	$port->{id} = $port_id;
	if ($port->FetchByID()) {
		$port->RefreshFromFiles($FreshPorts::Constants::HEAD, 0, 0, '');
		$port->save();
	} else {
		FreshPorts::Utilities::ReportError('warning', "Could not retrieve port ($port_id)", 1);
	}
}
