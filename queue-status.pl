#!/usr/bin/perl -w
#
# $Id: queue-status.pl,v 1.1 2010-10-02 02:33:59 dan Exp $
#
# Copyright (c) 2001-2006 DVL Software
#

use strict;

use config;
use utilities;
use status;

sub SendNotice($) {
	my $Msg			= shift;
	my $hostname	= `hostname`;

	chomp $hostname;

	my $Body = 'At ' . $hostname . ' ' . $Msg . "\n";
	print $Body;
}

my $base=$FreshPorts::Config::QueueBaseDir;

my %queues = ('incoming' => '*.txt', 'retry' => '*.txt', 'recent' => '*.xml');
my %queue_names = ('incoming' => 'incoming', 'retry' => 'retry', 'recent' => 'processed');
my %report_non_zero = ('retry' => 1);

my $send_report = 0;
my $msg         = '';

foreach my $site (@FreshPorts::Status::sites) {
	$msg .= "SITE: $site ";
	while (my ($queue, $pattern) = each %queues) {
		my $Command = "find $base/$site/msgs/FreeBSD/$queue/";

		if ($pattern ne '') {
			$Command .= " -name \"$pattern\"";
		}
		$Command .= ' | wc -l';
	
		my $Count = `$Command`;
		chomp $Count;
		$Count = FreshPorts::Utilities::trim($Count);
		$msg .= " $queue: $Count ";

		if ($Count && defined($report_non_zero{$queue})) {
			$send_report = 1;
		}
	}

	$msg .= " ";
}

if ($send_report) {
	Sys::Syslog::syslog('notice', 'There is a problem with the FreshPorts queues');
	SendNotice($msg);
	exit(1)
} else {
	print 'Queues are OK';
}
