#
# $Id: messages.pm,v 1.1.2.2 2004-09-17 03:13:47 dan Exp $
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

1;
