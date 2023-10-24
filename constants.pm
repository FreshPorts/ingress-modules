#!/usr/local/bin/perl -w
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
$FreshPorts::Constants::MAIN				= 'main';
$FreshPorts::Constants::PORTS 				= 'ports';

#
# FreshPorts database repo names
#
# These are the names of the FreeBSD repos found within the FreshPorts database
# These the valid values in the repo.name field
#
$FreshPorts::Constants::Repo_DB_Doc                       = 'doc';
$FreshPorts::Constants::Repo_DB_Ports                     = 'ports';
$FreshPorts::Constants::Repo_DB_Src                       = 'src';


#
# These are the values to be used in the Repository field of the incoming XML files
# They reflect the different working copies of repos we are processing.
# It also helps us know what we are working on.
#
$FreshPorts::Constants::Repo_XML_Label_Doc                = 'doc';
$FreshPorts::Constants::Repo_XML_Label_Ports              = 'ports';
$FreshPorts::Constants::Repo_XML_Label_Ports_Quarterly    = 'ports-quarterly';
$FreshPorts::Constants::Repo_XML_Label_Src                = 'src';

#
# These names relate to the directory in which we find that repo on disk.
# They were taken from the repository names found at https://github.com/freebsd/
# in July 2020. They do not need to be kept up to date. They just have to reflect
# the directories used on disk.
# Interesting fact: we don't need this. We do not need to access the repo for
# doc and src commits. We have doc and src listed to be complete.
# $ ls ~freshports/ports-jail/var/db/repos/
# PORTS-2020Q2            PORTS-2020Q3            freebsd                 freebsd-ports
# PORTS-2020Q2-git        PORTS-head              freebsd-doc             freebsd-ports-quarterly
#
# 2021-04-06 - The FreeBSD ports tree via git became active earlier today.
# It seems these four constants are used only by ingress commit processing.
# Only port commits receive the additional processing which requires a repo
# for the freshports user. However, we have these four defined. Let's keep them
# and correct them for now. - Dan Langille
$FreshPorts::Constants::Repo_Dir_Name_Doc                 = 'doc';
$FreshPorts::Constants::Repo_Dir_Name_Ports               = 'ports';
$FreshPorts::Constants::Repo_Dir_Name_Ports_Quarterly     = 'ports-quarterly';
$FreshPorts::Constants::Repo_Dir_Name_Src                 = 'src';

# and we have svn repos

#
# How to translate the label (doc) to the repo directory (freebsd-doc)
# Well, we don't have to do this often, or at all, because we only access
# the repo for port commits, nothing else.
# This is how we relate an incoming XML file to a particular working copy of the repo.
#
%FreshPorts::Constants::GitRepos = (
   $FreshPorts::Constants::Repo_XML_Label_Doc             => $FreshPorts::Constants::Repo_Dir_Name_Doc,
   $FreshPorts::Constants::Repo_XML_Label_Ports           => $FreshPorts::Constants::Repo_Dir_Name_Ports,
   $FreshPorts::Constants::Repo_XML_Label_Ports_Quarterly => $FreshPorts::Constants::Repo_Dir_Name_Ports_Quarterly,
   $FreshPorts::Constants::Repo_XML_Label_Src             => $FreshPorts::Constants::Repo_Dir_Name_Src,
);

#
# With the GitRepos, the repo name on disk and the label we assign for XML both do not match the
# repo we want to use.
#
# freebsd-ports and freebsd-ports-quarterly both map to the ports tree.
#
# That relationship (XML label to name in the FreshPorts repo table) is mapped here.
# The repo table knows only: doc ports src
#
# On the left, we have the incoming values in the XML file.
# On the right, we have the name we use at https://github.com/freebsd/X
#
%FreshPorts::Constants::RepoLabelsToGitRepoNames = (
   $FreshPorts::Constants::Repo_XML_Label_Doc             => $FreshPorts::Constants::Repo_DB_Doc,
   $FreshPorts::Constants::Repo_XML_Label_Ports           => $FreshPorts::Constants::Repo_DB_Ports,
   $FreshPorts::Constants::Repo_XML_Label_Ports_Quarterly => $FreshPorts::Constants::Repo_DB_Ports,
   $FreshPorts::Constants::Repo_XML_Label_Src             => $FreshPorts::Constants::Repo_DB_Src,
 );


$FreshPorts::Constants::ReportIDMaintainerNotification	= 3;
$FreshPorts::Constants::ReportIDAnnouncements		= 4;
$FreshPorts::Constants::ReportDeletedPorts		= 5;

$FreshPorts::Constants::VERSION_REVISION_JOINER		= '_';

$FreshPorts::Constants::VUXML_URL                       = 'https://www.vuxml.org/freebsd/';

$FreshPorts::Constants::Notify_ports_moved              = 'notify_ports_moved';       # /usr/ports/MOVED
$FreshPorts::Constants::Notify_ports_updating           = 'notify_ports_updating';    # /usr/ports/UPDATING
$FreshPorts::Constants::Notify_port_updated             = 'notify_port_updated';      # a port has been updated
$FreshPorts::Constants::Notify_vuxml                    = 'notify_vuxml';             # vuxml has been updated
$FreshPorts::Constants::Notify_cvsroot_approvers        = 'notify_cvsroot_approvers'; # CVSROOT/approvers has been updated

#
# some special files
#
$FreshPorts::Constants::CVSROOT_Approvers		= 'CVSROOT/approvers';       # what we see in the commit msg
$FreshPorts::Constants::CVSROOT_Ports_Approvers		= 'CVSROOT-ports/approvers'; # what we need to fetch from cvsweb
$FreshPorts::Constants::Categories			= 'www/en/ports/categories';
$FreshPorts::Constants::VUXML				= '\/ports\/head\/security\/vuxml/vuln/(\d{4})?.xml';
$FreshPorts::Constants::PORTS_UPDATING			= '/ports/head/UPDATING';
$FreshPorts::Constants::PORTS_MOVED			= '/ports/head/MOVED';

# used by observer_commits.pm
$FreshPorts::Constants::Ports_HEAD_commit		= '/ports/head/';

# not used, yet. For completeness, matches Ports_HEAD_commit above
$FreshPorts::Constants::Ports_BRANCHES_commit		= '/ports/branches/';

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
