#!/usr/bin/perl
#
# $Id: caching.pm,v 1.1.2.1 2006-05-30 20:51:56 dan Exp $
#
# Copyright (c) 2001-2003 DVL Software
#

package FreshPorts::Caching;

use strict;
use utilities;
use config;
use Sys::Syslog;

require config;

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

sub RemovePortFromCache($,$) {
	my $this          = shift;
	my $category_name = shift;
	my $port_name     = shift;
	
	my $CachingFile = $FreshPorts::Config::CachingRoot . '/' . $category_name . '.' . $port_name;
	
	`rm $CachingFile`;
}

sub RemovePortsFromCache($) {
	my $this = shift;
	#
	# given the ports touched by this commit
	# remove each one from the cache
	#


	my $CommitLogPortsRef		= shift;
	my %CommitLogPorts			= %{$CommitLogPortsRef};

	my $port;
	my $error;
	my $ErrorFound = 0;

	print "# # # # Removing ports from the cache # # # #\n\n";
	while (my ($portname, $commit_log_ports) = each %CommitLogPorts) {
		$port = $commit_log_ports->{port};
		print "$port->{category}/$port->{name}\n";

		$this->RemovePortFromCache($port->{category}, $port->{name});
	}

	print "\n# # # # Finsihed: Removing ports from the cache # # # #\n\n";

	return $ErrorFound;
}



1;