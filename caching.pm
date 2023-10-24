#!/usr/local/bin/perl
#
# $Id: caching.pm,v 1.4 2008-09-29 06:11:39 dan Exp $
#
# Copyright (c) 2001-2006 DVL Software
#
#
# This is only valid on webserver hosts.
# It won't work as expected on ingress hosts.
#
# 2023-10-15 - To fix https://github.com/FreshPorts/freshports/issues/468
# I will modify this module to add entries to the cache clearing tables.

package FreshPorts::Caching;

use strict;
use FreshPorts::utilities;
use FreshPorts::config;
use Sys::Syslog;

require FreshPorts::config;

sub new {
	my $this  = {};
	my $class = shift;

	$this->{dbh}	= shift;

	bless $this;

	$this->_initialize();

	return $this;
}

sub _initialize {
}

sub RemovePortFromCache($;$;$) {
	my $this          = shift;
	my $port_id       = shift;
	my $category_name = shift;
	my $port_name     = shift;

	my $sql = 'insert into cache_clearing_ports (port_id, category, port) values (' . $this->{dbh}->quote($port_id) . ', ' . $this->{dbh}->quote($category_name) . ', ' . 
		$this->{dbh}->quote($port_name) . ')
	        ON CONFLICT DO NOTHING';

	print "sql is $sql\n";

	my $sth = $this->{dbh}->prepare($sql);
	if (!$sth->execute) {
		FreshPorts::Utilities::ReportError('warning', "Could not execute SQL $sql ... maybe invalid? ". $this->{dbh}->errstr, 1);
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

# I am sure this function can be removed - Mostly beacuse this module has long been a NOP, ever since the ingress and web
# functions split into two hosts.  But let's check the code later.
sub RemovePortsFromCache($) {
	my $this = shift;
	#
	# given the ports touched by this commit
	# remove each one from the cache
	#

	my $CommitLogPortsRef = shift;
	my %CommitLogPorts    = %{$CommitLogPortsRef};

	my $error;
	my $ErrorFound = 0;
	
	return;

	if (scalar %CommitLogPorts) {
		print "# # # # Removing ports from the cache # # # #\n\n";
		while (my ($candidate, ) = each %CommitLogPorts) {
			my ($category, $port) = split('/', $candidate);
			print "$category/$port\n";

			#
			# somehow, things have been working without this explicit removal.
			# I suspect this upate might be handled within triggers
			#
			print "# # # # RemovePortsFromCache is out of date because RemovePortFromCache needs port id # # # #\n\n";
#			$this->RemovePortFromCache($category, $port);
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

	my $sql;
	my $sth;

	if (scalar %Files) {
		print "# # # # Removing files from the cache # # # #\n\n";
		while (my ($candidate, ) = each %Files) {
			print "$candidate\n";

			$sql = 'insert into cache_clearing_files (pathname) values (' . $this->{dbh}->quote($candidate) . ')
			        ON CONFLICT ON CONSTRAINT cache_clearing_files_pathname DO NOTHING';

			print "sql is $sql\n";

			$sth = $this->{dbh}->prepare($sql);
			if (!$sth->execute) {
				FreshPorts::Utilities::ReportError('warning', "Could not execute SQL $sql ... maybe invalid? ". $this->{dbh}->errstr, 1);
			}
		}
		# after populating the cache_clearing_files table, we notify.
        $sth = $this->{dbh}->prepare("notify file_updated");
        $sth->execute ||
            die "Could not execute SQL $sql ... maybe invalid?";

		print "\n# # # # Finished: Removing files from the cache # # # #\n\n";
	} else {
		print "This commit had no files that need to be removed from the cache\n";
	}

	return $ErrorFound;
}

1;
