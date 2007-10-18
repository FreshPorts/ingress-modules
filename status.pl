#!/usr/bin/perl -w
#
# $Id: status.pl,v 1.4 2007-10-18 17:52:39 dan Exp $
#
# Copyright (c) 2001-2006 DVL Software
#

use strict;

use email;
use config;
use utilities;
use status;

sub SendNotice($) {
	my $Msg			= shift;
	my $hostname	= `hostname`;

	chomp $hostname;

	my $To           = $FreshPorts::Config::SystemOwnerEmail;
	my $From         = 'FreshPorts Daemon <FreshPorts@FreshPorts.org>';
	my $Subject      = 'FreshPorts -- queue status';
	my $ExtraHeaders = '';
	$ExtraHeaders   .= 'X-FreshPorts-Status: non-zero queues found' . "\n";
	$ExtraHeaders   .= 'Auto-Submitted: auto-generated'             . "\n";
	$ExtraHeaders   .= 'Precedence: bulk'                           . "\n";


	my $Body = 'At ' . $hostname . "\n\n" . $Msg;

	FreshPorts::email::SendMail($From, $To, '', $Subject, $Body, $ExtraHeaders);
}

my $base=$FreshPorts::Config::QueueBaseDir;

my %queues = ('incoming' => '*.txt', 'retry' => '*.txt', 'recent' => '*.xml');
my %queue_names = ('incoming' => 'incoming', 'retry' => 'retry', 'recent' => 'processed');
my %report_non_zero = ('retry' => 1);

my $send_report = 0;
my $msg         = '';

foreach my $site (@FreshPorts::Status::sites) {
	$msg .= "SITE: $site\n";
	while (my ($queue, $pattern) = each %queues) {
		my $Command = "find $base/$site/msgs/FreeBSD/$queue/";
		if ($pattern ne '') {
			$Command .= " -name \"$pattern\"";
		}
		$Command .= ' | wc -l';
	
		my $Count = `$Command`;
		chomp $Count;
		$Count = FreshPorts::Utilities::trim($Count);
		$msg .= " $queue: $Count\n";

		if ($Count && defined($report_non_zero{$queue})) {
			$send_report = 1;
		}
	}

	$msg .= "\n";
}

if ($send_report) {
	Sys::Syslog::syslog('notice', $msg);
	SendNotice($msg);
}
