#
# $Id: messages.pm,v 1.1.2.3 2004-12-19 23:14:59 dan Exp $
#
# Copyright (c) 2004 DVL Software
#

#
# These are the messages passed around between Observables and Observers

package FreshPorts::Messages;

$FreshPorts::Messages::ProcessingBegins	= 'ProcessingBegins';
$FreshPorts::Messages::CommitSaved		= 'CommitSaved';
$FreshPorts::Messages::FileUpdate		= 'FileUpdate';
$FreshPorts::Messages::PortsRefreshed	= 'PortsRefreshed';
$FreshPorts::Messages::ProcessingDone	= 'ProcessingDone';
$FreshPorts::Messages::PortsFreezeCheck	= 'PortsFreezeCheck';
$FreshPorts::Messages::FilesFetched		= 'FilesFetched';

1;
