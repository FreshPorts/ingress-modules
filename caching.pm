#!/usr/bin/perl
#
# $Id: caching.pm,v 1.1.2.12 2006-11-01 14:39:14 dan Exp $
#
# Copyright (c) 2001-2006 DVL Software
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

	return $this;
}

sub _initialize {
}

sub RemovePortFromCache($;$) {
	my $this          = shift;
	my $category_name = shift;
	my $port_name     = shift;

	my $CachingFile = $FreshPorts::Config::CachingRoot . '/cache/ports/' . $category_name . '/' . $port_name . '.Detail.*.html';
	
	print "checking cache for '$CachingFile'\n";
	if (-e "$CachingFile") {
		print "cache entry exists.  removing it\n";

		if (!unlink("$CachingFile")) {
			print "!!!unable to delete $CachingFile\n";
		}
	} else {
		print "nothing in the cache to remove\n"
	}
}

sub RemovePortsFromCache($) {
	my $this = shift;
	#
	# given the ports touched by this commit
	# remove each one from the cache
	#

	my $CommitLogPortsRef	= shift;
	my %CommitLogPorts		= %{$CommitLogPortsRef};

	my $port;
	my $error;
	my $ErrorFound = 0;

	if (scalar %CommitLogPorts) {
		print "# # # # Removing ports from the cache # # # #\n\n";
		while (my ($candidate, ) = each %CommitLogPorts) {
			my ($category, $port) = split('/', $candidate);
			print "$category/$port\n";

			$this->RemovePortFromCache($category, $port);
		}
		print "\n# # # # Finished: Removing ports from the cache # # # #\n\n";
	} else {
		print "This commit had nothing that needs to be removed from the cache\n";
	}

	return $ErrorFound;
}

1;
