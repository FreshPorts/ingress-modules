#
# $Id: constants.pm,v 1.7.2.7 2003-09-24 13:48:16 dan Exp $
#
# Copyright (c) 2001-2003 DVL Software
#

package FreshPorts::Constants;

use strict;

#
# Database sequence IDs
#

$FreshPorts::Constants::ports_seq					= "ports_id_seq";
$FreshPorts::Constants::commit_log_seq				= "commit_log_id_seq";
$FreshPorts::Constants::commit_log_elements_seq		= "commit_log_elements_id_seq";
$FreshPorts::Constants::commit_log_seq				= "commit_log_id_seq";
$FreshPorts::Constants::system_branch_seq			= "system_branch_id_seq";

$FreshPorts::Constants::ADD							= 'Add';
$FreshPorts::Constants::MODIFY						= 'Modify';
$FreshPorts::Constants::REMOVE						= 'Remove';

$FreshPorts::Constants::FreeBSD						= 'FreeBSD';


$FreshPorts::Constants::FILE_MAKEFILE				= "Makefile";

#
# These are the entries within /usr/ports/ which we ignore
# and /usr/ports/<category> which FreshPorts does not track
#
%FreshPorts::Constants::IgnoredItems = (
	"Attic"			=> 1,
	"distfiles"		=> 2,
	"Mk"			=> 3,
	"Tools"			=> 4,
	"Templates"		=> 5,
	"Makefile"		=> 6,
	"pkg"			=> 7,
	"Makefile.inc"	=> 8,
);

$FreshPorts::Constants::UsualPortsTreeLocation			= '/usr';

$FreshPorts::Constants::HEAD							= 'HEAD';

$FreshPorts::Constants::ReportIDMaintainerNotification	= 3;
$FreshPorts::Constants::ReportIDAnnouncements			= 4;
$FreshPorts::Constants::ReportDeletedPorts				= 5;

1;
