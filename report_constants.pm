#!/usr/local/bin/perl -w
#
# $Id: report_constants.pm,v 1.3 2007-04-02 20:11:19 dan Exp $
#
# Copyright (c) 2002-2026 Dan Langille
#

package FreshPorts::ReportConstants;

require FreshPorts::config;

#
# these are reports.id values
#
$FreshPorts::ReportConstants::Notification	= 1;
$FreshPorts::ReportConstants::NewPorts		= 2;
$FreshPorts::ReportConstants::Security		= 5;
$FreshPorts::ReportConstants::MaintainerPorts	= 6;

my $WatchURL              = $FreshPorts::Config::FreshPortsURL . "watch.php";
my $ReportSubscriptionURL = $FreshPorts::Config::FreshPortsURL . "report-subscriptions.php";


$FreshPorts::ReportConstants::Footer			= "======================================

Please refer to $WatchURL for details.

-- 

You are receiving this message as part of the service you joined at
$FreshPorts::Config::FreshPortsURL - You can unsubscribe at
$ReportSubscriptionURL

If a problem occurs, please send details to postmaster\@FreshPorts.org";

1;
