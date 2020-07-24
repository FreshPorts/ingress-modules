#
# $Id: constants.pm,v 1.16 2012-12-21 18:20:53 dan Exp $
#
# Copyright (c) 2001-2006 DVL Software
#

package FreshPorts::Constants;

use strict;

#
# Database sequence IDs
#

$FreshPorts::Constants::ports_seq			= "ports_id_seq";
$FreshPorts::Constants::commit_log_seq			= "commit_log_id_seq";
$FreshPorts::Constants::commit_log_elements_seq		= "commit_log_elements_id_seq";
$FreshPorts::Constants::commit_log_seq			= "commit_log_id_seq";
$FreshPorts::Constants::system_branch_seq		= "system_branch_id_seq";
$FreshPorts::Constants::sanity_test_failures_seq	= "sanity_test_failures_id_seq";

# for VuXML
$FreshPorts::Constants::vuxml_seq			= "vuxml_id_seq";
$FreshPorts::Constants::vuxml_affected_seq		= "vuxml_affected_id_seq";
$FreshPorts::Constants::vuxml_names_seq			= "vuxml_names_id_seq";
$FreshPorts::Constants::vuxml_ranges_seq		= "vuxml_ranges_id_seq";
$FreshPorts::Constants::vuxml_references_seq		= "vuxml_references_id_seq";

$FreshPorts::Constants::ADD				= 'Add';
$FreshPorts::Constants::MODIFY				= 'Modify';
$FreshPorts::Constants::REMOVE				= 'Remove';
$FreshPorts::Constants::DELETE				= 'Delete'; # added for git
$FreshPorts::Constants::RENAME				= 'Rename'; # added for git

$FreshPorts::Constants::FreeBSD				= 'FreeBSD';


$FreshPorts::Constants::FILE_MAKEFILE			= "Makefile";

#
# These are the entries within /usr/ports/ which we ignore
# and /usr/ports/<category> which FreshPorts does not track
#
%FreshPorts::Constants::IgnoredItems = (
	"Attic"        => 1,
	"distfiles"    => 2,
	"Mk"           => 3,
	"Tools"        => 4,
	"Templates"    => 5,
	"Makefile"     => 6,
	"Makefile.inc" => 7,
	"CVSROOT"      => 8,
	"base"         => 9,
);

$FreshPorts::Constants::Subversion = 'subversion';
$FreshPorts::Constants::Git        = 'git';

# These are the valid repositories we use. This relates to the repository column of the repo table.
# The values are not relevant.
%FreshPorts::Constants::Repositories = (
	$FreshPorts::Constants::Subversion => 1,
	$FreshPorts::Constants::Git        => 2,
);

$FreshPorts::Constants::UsualPortsTreeLocation		= '/usr/ports';
$FreshPorts::Constants::DISTDIR				= '/usr/ports/distfiles';

$FreshPorts::Constants::HEAD				= 'head';
$FreshPorts::Constants::MASTER				= 'master';
$FreshPorts::Constants::PORTS 				= 'ports';

$FreshPorts::Constants::Repo_Docs                       = 'freebsd-docs';
$FreshPorts::Constants::Repo_Ports                      = 'freebsd-ports';
$FreshPorts::Constants::Repo_Src                        = 'freebsd';


%FreshPorts::Constants::GitRepos = (
   $FreshPorts::Constants::Repo_Docs  => $FreshPorts::Constants::Repo_Docs,
   $FreshPorts::Constants::Repo_Ports => $FreshPorts::Constants::Repo_Ports,
   $FreshPorts::Constants::Repo_Src   => $FreshPorts::Constants::Repo_Src,
);

$FreshPorts::Constants::ReportIDMaintainerNotification	= 3;
$FreshPorts::Constants::ReportIDAnnouncements		= 4;
$FreshPorts::Constants::ReportDeletedPorts		= 5;

$FreshPorts::Constants::VERSION_REVISION_JOINER		= '_';

$FreshPorts::Constants::VUXML_URL                       = 'https://www.vuxml.org/freebsd/';

$FreshPorts::Constants::Notify_ports_moved		= 'notify_ports_moved';			# /usr/ports/MOVED
$FreshPorts::Constants::Notify_ports_updating		= 'notify_ports_updating';		# /usr/ports/UPDATING
$FreshPorts::Constants::Notify_port_updated		= 'notify_port_updated';		# a port has been updated
$FreshPorts::Constants::Notify_vuxml			= 'notify_vuxml';				# vuxml has been updated
$FreshPorts::Constants::Notify_cvsroot_approvers	= 'notify_cvsroot_approvers';	# CVSROOT/approvers has been updated

#
# some special files
#
$FreshPorts::Constants::CVSROOT_Approvers		= 'CVSROOT/approvers';       # what we see in the commit msg
$FreshPorts::Constants::CVSROOT_Ports_Approvers		= 'CVSROOT-ports/approvers'; # what we need to fetch from cvsweb
$FreshPorts::Constants::Categories			= 'www/en/ports/categories';
$FreshPorts::Constants::VUXML				= '/ports/head/security/vuxml/vuln.xml';
$FreshPorts::Constants::PORTS_UPDATING			= '/ports/head/UPDATING';
$FreshPorts::Constants::PORTS_MOVED			= '/ports/head/MOVED';

#
# Special repositories we watch
#

$FreshPorts::Constants::Repository_Ports                = 'ports';

#
# database connection types
#

# e.g. my $dbh = FreshPorts::Database::GetDBHandle($FreshPorts::Constants::DB_ConnectionType => $FreshPorts::Constants::DB_ConnectionType_ReadOnly);
# use this in the call to FreshPorts::Database::GetDBHandle
$FreshPorts::Constants::DB_ConnectionType           = 'ConnectionType'; 

# The possible values which can be assigned to the ConnectionType parameter when calling GetDBHandle:

$FreshPorts::Constants::DB_ConnectionType_ReadOnly  = 'RO';             # read-only. still rather limited in what you can read
$FreshPorts::Constants::DB_ConnectionType_Commits   = 'Commits';        # used for inserting and processing new commits
$FreshPorts::Constants::DB_ConnectionType_Listener  = 'listen';         # for the fp-listen daemon

1;
