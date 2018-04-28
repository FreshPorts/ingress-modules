#!/usr/local/bin/perl
#
# $Id: caching.pm,v 1.4 2008-09-29 06:11:39 dan Exp $
#
# Copyright (c) 2001-2006 DVL Software
#

package FreshPorts::Caching;

use strict;
use FreshPorts::utilities;
use FreshPorts::config;
use Syslog;

require FreshPorts::config;

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

	my $CachingFile = $FreshPorts::Config::CachingRoot . '/cache/ports/' . $category_name . '/' . $port_name . '/*.html';
	
	print "checking cache for '$CachingFile'\n";
	my @CacheEntries = glob($CachingFile);
	if (scalar @CacheEntries) {
		print "cache items exists.  removing them\n";
		
		foreach my $file (@CacheEntries) {
			if (!unlink($file)) {
				print "!!!unable to delete $file\n";
			}
		}
	} else {
		print "nothing in the cache to remove\n"
	}
}

sub RemoveFileFromCache($;$) {
	my $this      = shift;
	my $file_name = shift;

	my $CachingFile = $FreshPorts::Config::CachingRoot . '/cache/ports/' . $file_name . '.*.html';
	
	print "checking cache for '$CachingFile'\n";
	my @CacheEntries = glob($CachingFile);
	if (scalar @CacheEntries) {
		print "cache items exists.  removing them\n";
		
		foreach my $file (@CacheEntries) {
			if (!unlink($file)) {
				print "!!!unable to delete $file\n";
			}
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
		print "This commit had no ports that need to be removed from the cache\n";
	}

	return $ErrorFound;
}

sub RemoveFilesFromCache($) {
	my $this = shift;
	#
	# given the files touched by this commit
	# remove each one from the cache
	#

	my $FilesRef	= shift;
	my %Files		= %{$FilesRef};

	my $error;
	my $ErrorFound = 0;

	if (scalar %Files) {
		print "# # # # Removing files from the cache # # # #\n\n";
		while (my ($candidate, ) = each %Files) {
			print "$candidate\n";

			$this->RemoveFileFromCache($candidate);
		}
		print "\n# # # # Finished: Removing files from the cache # # # #\n\n";
	} else {
		print "This commit had no files that need to be removed from the cache\n";
	}

	return $ErrorFound;
}

1;
