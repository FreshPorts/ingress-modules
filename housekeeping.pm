#!/usr/bin/perl
#
# $Id: housekeeping.pm,v 1.1.2.3 2002-12-17 16:27:18 dan Exp $
#
# Copyright (c) 2002 DVL Software
#

package FreshPorts::Housekeeping;

use strict;
use utilities;

$FreshPorts::Housekeeping::Refresh      = 1;
$FreshPorts::Housekeeping::RefreshPorts = 2;

sub new {
	my $this		= {};
	my $class		= shift;
	$this->{dbh}	= shift;
	bless $this;
	$this->_initialize();
	return $this
}

sub _initialize {
}

sub refreshdone {
	my $this  = shift;
	my $value = shift;

	my $dbh = $this->{dbh}; # just a short cut...
	my $sth;
	my $sql;
	my @row;

	# we are always updating here.  It is cleared during the stored procedure RecordLastestPortCommits
	$sql = "update housekeeping set refresh_now = $value where id = 1";

	print "sql is $sql\n";

	$sth = $this->{dbh}->prepare($sql);
	if (!$sth->execute) {
		FreshPorts::Utilities::ReportError('warning', "Could not execute SQL $sql ... maybe invalid? ". $dbh->errstr, 1);
	}
}

sub read {
	my $this = shift;

	my $dbh = $this->{dbh}; # just a short cut...
	my $sth;
	my $sql;
	my @row;

	$sql = "select last_port_commit, refresh_now from housekeeping where id = 1";
	$sth = $dbh->prepare($sql);
	$sth->execute ||
		FreshPorts::Utilities::ReportError('warning', "Could not execute SQL $sql ... maybe invalid?", 1);

	@row=$sth->fetchrow_array;

	$sth->finish();

	$this->{last_port_commit}	= $row[0];
	$this->{refresh_now}			= $row[1];

	$sql = "SELECT COUNT(*) from daily_refreshes";
	$sth = $dbh->prepare($sql);
	$sth->execute ||
		FreshPorts::Utilities::ReportError('warning', "Could not execute SQL $sql ... maybe invalid?", 1);

	@row=$sth->fetchrow_array;

	$sth->finish();

	$this->{daily_refreshes}	= $row[0];	
}

1;