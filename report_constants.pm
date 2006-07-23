#
# $Id: report_constants.pm,v 1.1.2.6 2006-07-23 13:17:26 dan Exp $
#
# Copyright (c) 2002-2006 DVL Software
#

package FreshPorts::ReportConstants;

require config;

$FreshPorts::ReportConstants::Notification	= 1;
$FreshPorts::ReportConstants::NewPorts		= 2;
$FreshPorts::ReportConstants::Security		= 5;

my $WatchURL              = $FreshPorts::Config::FreshPortsURL . "watch.php";
my $ReportSubscriptionURL = $FreshPorts::Config::FreshPortsURL . "report-subscriptions.php";


$FreshPorts::ReportConstants::Footer			= "======================================

Please refer to $WatchURL for details.

-- 

You are receiving this message as part of the service you joined at
$FreshPorts::Config::FreshPortsURL.  You can unsubscribe at
$ReportSubscriptionURL.

If a problem occurs, please send details to postmaster\@FreshPorts.org.";

1;
