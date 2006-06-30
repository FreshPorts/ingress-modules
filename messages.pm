#
# $Id: messages.pm,v 1.1.2.6 2006-06-30 01:14:15 dan Exp $
#
# Copyright (c) 2004-2006 DVL Software
#

#
# These are the messages passed around between Observables and Observers

package FreshPorts::Messages;

$FreshPorts::Messages::ProcessingBegins		= 'ProcessingBegins';
$FreshPorts::Messages::UpdateBegins			= 'UpdateBegins';
$FreshPorts::Messages::UpdateEnds			= 'UpdateEnds';
$FreshPorts::Messages::CommitSaved			= 'CommitSaved';
$FreshPorts::Messages::FileUpdate			= 'FileUpdate';
$FreshPorts::Messages::PortsRefreshed		= 'PortsRefreshed';
$FreshPorts::Messages::ProcessingDone		= 'ProcessingDone';
$FreshPorts::Messages::PortsFreezeCheck		= 'PortsFreezeCheck';
$FreshPorts::Messages::FilesFetched			= 'FilesFetched';
$FreshPorts::Messages::TransactionCommitted	= 'TransactionCommitted';

1;
