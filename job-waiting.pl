#!/usr/bin/perl -w
#
# $Id: job-waiting.pl,v 1.1.2.1 2005-08-03 12:25:18 dan Exp $
#
# Copyright (c) 1999-2005 DVL Software
#

use strict;

use DBI;
use database;
use cache;
use commit_log_ports_ignore;
use system_status;
my $dbh;

my $DaysRefreshed;

my %Jobs = (
	$FreshPorts::Config::MovedFileFlag    => 'process_moved.sh',
	$FreshPorts::Config::UpdatingFileFlag => 'process_updating.sh',
	$FreshPorts::Config::VuXMLFileFlag    => 'process_vuxml.sh'
	);

while (my ($flag, $script) = each %Jobs) {
	if (-f $flag) {
		Sys::Syslog::syslog('notice', "$flag exists.  must run $script");
		`$FreshPorts::Config::scriptpath/$script`
	} else {
		Sys::Syslog::syslog('notice', "flag not set.  no work for $script");
	}
}