#!/usr/bin/perl -w
#
# $Id: status.pl,v 1.1.2.1 2003-11-24 16:39:57 dan Exp $
#
# Copyright (c) 2001-2003 DVL Software
#

use strict;
use lib "$ENV{HOME}/scripts";

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
	my $ExtraHeaders = 'X-FreshPorts-Status: non-zero queues found';


	my $Body = 'At ' . $hostname . "\n\n" . $Msg;

	FreshPorts::email::SendMail($From, $To, '', $Subject, $Body, $ExtraHeaders);
}

my $base="$ENV{HOME}/FreshPorts";

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
	SendNotice($msg);
}