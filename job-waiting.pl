#!/usr/local/bin/perl -w
#
# $Id: job-waiting.pl,v 1.3 2007-01-29 00:17:35 dan Exp $
#
# Copyright (c) 1999-2007 DVL Software
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
	$FreshPorts::Config::MovedFileFlag            => 'process_moved.sh',
	$FreshPorts::Config::UpdatingFileFlag         => 'process_updating.sh',
	$FreshPorts::Config::VuXMLFileFlag            => 'process_vuxml.sh',
	$FreshPorts::Config::WWWENPortsCategoriesFlag => 'process_www_en_ports_categories.sh'
	);

while (my ($flag, $script) = each %Jobs) {
	if (-f $flag) {
		Sys::Syslog::syslog('notice', "$flag exists.  About to run $script");
		`$FreshPorts::Config::scriptpath/$script`;
		Sys::Syslog::syslog('notice', "Finished running $script");
	} else {
		Sys::Syslog::syslog('notice', "flag '$flag' not set.  no work for $script");
	}
}