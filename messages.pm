#
# $Id: messages.pm,v 1.1.2.1 2004-08-18 16:47:13 dan Exp $
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

1;
