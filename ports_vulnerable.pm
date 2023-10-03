#!/usr/local/bin/perl -w
#
# $Id: ports_vulnerable.pm,v 1.3 2012-03-31 20:38:04 dan Exp $
#
# Copyright (c) 2001-2003 DVL Software
#

package FreshPorts::PortsVulnerable;

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
}

sub AdjustVulnerabilityCountForPort($) {
	# TODO not sure how we'd calculate this on the fly.
	# The edge case: a vuln affects a port.  vuxml is updated, port is no longer affected.
	# Processing that vuln again will no longer affect that port, so the count will be outdated.  Conclusion: we need to start keeping track of vuln->port relationships.  At present,
	# it's vuln->commit
	
	my $this    = shift;
	my $port_id = shift;

	my $dbh = $this->{dbh}; # just a short cut...
	my $sth;
	my $sql;
	my $row;

	my $count = undef;

	$sql = "select PortsVulnerabilityCountAdjust($port_id) as count";

	print "\$sql='$sql'\n";

	$sth = $dbh->prepare($sql);
	if (!$sth->execute) {
		FreshPorts::Utilities::ReportError('warning', "Could not execute SQL $sql", 1);
	}

	$row = $sth->fetchrow_hashref();

	$sth->finish();

	# return the number of vulnerabilities found
	if ($row) {
		$count = $row->{count};
	}

	return $count;
}

sub PortsVulnerabilityCountAdjust($) {
	my $this = shift;
	#
	# given the ports touched by this commit
	# mark any commits that are vulnerable
	#


	my $CommitLogPortsRef		= shift;
	my %CommitLogPorts			= %{$CommitLogPortsRef};

	my $port;
	my $error;
	my $ErrorFound = 0;

	#
	# mark each and every port we are told about, if vulnerable
	#
	print "# # # # Updating ports_vulnerable table # # # #\n\n";
	while (my ($portname, $commit_log_ports) = each %CommitLogPorts) {
		$port = $commit_log_ports->{port};
		print "port = $portname, port_id = '$port->{id}', category_id='$port->{category_id}'\n";

		$this->AdjustVulnerabilityCountForPort($port->{id});
	}

	print "# # # # done updating ports_vulnerable table # # # #\n\n";

	return $ErrorFound;
}

1;
