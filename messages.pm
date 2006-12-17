#
# $Id: messages.pm,v 1.2 2006-12-17 12:04:01 dan Exp $
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
