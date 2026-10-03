#!/usr/local/bin/perl
# 
# $Id: xml_munge.pm,v 1.18 2012-10-23 16:31:04 dan Exp $
#
# Copyright (c) 2001-2026 Dan Langille
#
# Parse cvs messages in XML format so they can be put into a database
# Version 4 - uses DTD version 0.12
#
#
# return values
#  1 - incorrect calling of script.  check your parameters
#  2 - this message id is already in the database
#  3 - No SystemID found for OS  - this OS     isn't being followed by FreshPorts
#  4 - No SystemBranchID found   - this branch isn't being followed by FreshPorts
#  5 - invalid file action found - the file action found wasn't recognized. Check the DTD.
#  6 - element id was not found  - possible problem adding new element to database.
#  7 - this messages does not deal with the ports subsystem.
#

# we make a great deal of use of a global variable Updates.  We should fix that up.
#


# use strict;


package FreshPorts::XML_Munge_git;

use base qw( Class::Observable );

require Sys::Syslog;

use FreshPorts::element;
use FreshPorts::verifyport;
use FreshPorts::branches;
use FreshPorts::config;
use FreshPorts::constants;
use FreshPorts::commit_log;
use FreshPorts::commit_log_branches;
use FreshPorts::commit_log_element;
use FreshPorts::db_utils;
use FreshPorts::database;
use FreshPorts::utilities;
use FreshPorts::committer_opt_in;
use FreshPorts::non_ports;
use FreshPorts::messages;
use FreshPorts::sanity_test_failures;

use XML::Node;
use DBI;
use Email::Address::XS qw(split_address);

my $commit_log_id           = 0;
my $debug                   = 0;
my $overwrite               = 0;
my $refresh_ports           = 1;  # refresh any ports touched by a commit
my $fetch_before_refresh    = 1;  # by default, we fetch files from the repo
                                  # before refreshing the database

my $SystemID;                     # the system id for this update.  Usually 'FreeBSD' => 1
my $SystemBranchID;               # the system version id for this update.  Usually 'head' => 1

my @Files;                        # files affected by this commit

my $id;                           # this will get the message id once we know it.
                                  # impelemented only for observable class

my $_RollbackNeeded         = 0;  # set by Rollback_Needed()

#
# a file can be added to the repository, deleted (removed) from the repository,
# or modified in the repository.
#
my %ValidFileActions = ( $FreshPorts::Constants::ADD    => "A",
                         $FreshPorts::Constants::DELETE => "R", # matches the Remove for subversion commits
                         $FreshPorts::Constants::MODIFY => "M",
                         $FreshPorts::Constants::RENAME => "r");

my %BranchConversions = ( 'main' => 'head' );

my %Updates;

my $self;	# for use by functions that cannot get this value (i.e. handler_*)

sub new {
	my $this  = {};
	my $class = shift;

	$this->{dbh} = shift;

	bless $this;

	$this->_initialize();

	return $this
}


sub _initialize {
	my $this = shift;

	# save self for use by function that cannot get access to it.
	$self = $this
}	


sub process {
	my ( $this ) = @_;

	$this->main;

	return $_RollbackNeeded;
}

sub usage {
	my $this = shift;

	print "USAGE : $0 INPUTFILE [-D] [-O] [-r] [-R]\n";
	print "   -D : debug\n";
	print "   -O : overwrite any existing commit with the same message id\n";
	print "   -r : do not fetch from CVS before refreshing database\n";
	print "   -R : do not refresh the port at all\n";
}

#####
# Main Processing Routine
##### 

sub main {
	my $this = shift;

	my $p = XML::Node->new();

	if (($#ARGV+1) >= 1) {
		$inputfile = $ARGV[0];
		if (-f $inputfile) {
		} else {
			print "please specify an input file name which exists\n";
			exit 1;
		}
		my $i;

		for ($i = 1; $i < ($#ARGV+1); $i++) {
			print "checking arg $i\n";
			if ($ARGV[$i] eq '-D') {
				print "debugging....\n";
				$debug = 1;
				next;
			}

			if ($ARGV[$i] eq '-O') {
				print "overwriting....\n";
				$overwrite = 1;
				next;
			}

			if ($ARGV[$i] eq '-r') {
				# useful if we only want to use
				# what's on disk.
				print "not fetching before refresh....\n";
				$fetch_before_refresh = 0;
				next;
			}

			if ($ARGV[$i] eq '-R') {
				# do not refresh the ports.  just process the commit
				print "not refreshing at all....\n";
				$refresh_ports = 0;
				next;
			}

			# we have found arguments we know nothing about
			print 'unknown argument ' . $ARGV[$i] . "\n";
			$this->usage();
			exit 1;
		}
	} else {
		usage();
		exit 1;
	}

	$self->notify_observers($FreshPorts::Messages::ProcessingBegins);
	$this->SetupParser($p);

	print "Processing file [$inputfile]...\n";

	print "dbname = $FreshPorts::Config::dbname\n";

	print "parsing file now\n";

	$p->parsefile($inputfile);
}

sub SetupParser($) {
	my $this = shift;

	my $p = shift;

	$p->register(">UPDATES",                               "start" => \&handle_updates_start);
	$p->register(">UPDATES>UPDATE",                        "start" => \&handle_update_start);

	$p->register(">UPDATES>UPDATE>DATE:Year",              "attr"  => \$Updates{dateyear});
	$p->register(">UPDATES>UPDATE>DATE:Month",             "attr"  => \$Updates{datemonth});
	$p->register(">UPDATES>UPDATE>DATE:Day",               "attr"  => \$Updates{dateday});

	$p->register(">UPDATES>UPDATE>TIME:Hour",              "attr"  => \$Updates{timehour});
	$p->register(">UPDATES>UPDATE>TIME:Minute",            "attr"  => \$Updates{timeminute});
	$p->register(">UPDATES>UPDATE>TIME:Second",            "attr"  => \$Updates{timesecond});
	$p->register(">UPDATES>UPDATE>TIME:Timezone",          "attr"  => \$Updates{timezone});

	$p->register(">UPDATES>UPDATE>OS:Id",                  "attr"  => \$Updates{os});

	#
	# EDIT 2020-11-17 - Updates{branch_git} is the branch name supplied by git.  e.g. main, branches/20202Q4
	# EDIT 2020-11-17 - removing all references to $Updates{branch} 
	#
	# for git, let's put branch in branch_git
	# will will populate $Updates{} with the converted value. e.g. main -> head
	# and branches/2020Q3 -> 2020Q3
	#
	$p->register(">UPDATES>UPDATE>OS:Branch",              "attr"  => \$Updates{branch_git});
	$p->register(">UPDATES>UPDATE>OS",                     "end"   => \&handle_os_end);
        
	$p->register(">UPDATES>UPDATE>LOG",                    "char"  => \$Updates{log});

	$p->register(">UPDATES>UPDATE>PEOPLE>COMMITTER:CommitterName",  "attr"  => \$Updates{committerName});
	$p->register(">UPDATES>UPDATE>PEOPLE>COMMITTER:CommitterEmail", "attr"  => \$Updates{committerEmail});
	$p->register(">UPDATES>UPDATE>PEOPLE>COMMITTER",                "end"   => \&handle_committer_end);

	$p->register(">UPDATES>UPDATE>PEOPLE>AUTHOR:AuthorName",        "attr"  => \$Updates{authorName});
	$p->register(">UPDATES>UPDATE>PEOPLE>AUTHOR:AuthorEmail",       "attr"  => \$Updates{authorEmail});
	$p->register(">UPDATES>UPDATE>PEOPLE>AUTHOR",                   "end"   => \&handle_author_end);

	$p->register(">UPDATES>UPDATE>COMMIT:Hash",            "attr"  => \$Updates{commit_hash});
	$p->register(">UPDATES>UPDATE>COMMIT:HashShort",       "attr"  => \$Updates{commit_hash_short});
	$p->register(">UPDATES>UPDATE>COMMIT:Subject",         "attr"  => \$Updates{MessageSubject});
	$p->register(">UPDATES>UPDATE>COMMIT:EncodingLosses",  "attr"  => \$Updates{MessageEncodingLosses});
	$p->register(">UPDATES>UPDATE>COMMIT:Repository",      "attr"  => \$Updates{repository});
	$p->register(">UPDATES>UPDATE>COMMIT",                 "end"   => \&handle_message_end);

	$p->register(">UPDATES>UPDATE>FILES>FILE:Path",        "attr"  => \$Updates{FilePath});
	$p->register(">UPDATES>UPDATE>FILES>FILE:Action",      "attr"  => \$Updates{FileAction});

	$p->register(">UPDATES>UPDATE>FILES>FILE",             "end"   => \&handle_file_end);


	$p->register(">UPDATES>UPDATE",                        "end"   => \&handle_update_end);
	$p->register(">UPDATES",                               "end"   => \&handle_updates_end);

	print "finished setting up the Parser\n";
}

sub handle_updates_start {
	print "\n\n *** start of all updates ***\n";
}

sub handle_update_start {
	print "\n --- start of an update --- \n";
	$self->notify_observers($FreshPorts::Messages::UpdateBegins);

	#
	# make sure we initialize things correctly for each message.
	# this might not be much use when doing just one message
	# at a time.  But if we start processing multiple messages
	# with each invocation of this script, it might be useful
	#
	FreshPorts::VerifyPort::InitialiseNewMessage();
} 

sub handle_os_end {
	print "\n --- end of OS --- \n";
	
	#
	# we want to remove any leading 'branches/' from the string.
	# we want just 2020Q3, for example
	#

	print "OS is '$Updates{os}' : branch = '$Updates{branch_git}' for git\n";
	
	# When we moved from subversion to git, we needed to convert branch from
	# main to head, because everything we need here is based on head.
	#
	# $Updates{branch_for_files} : for database related actions (finding a port) e.g. head or 2020Q3
	# $Updates{branch_git}       : for repository related actions (git checkout)
	#
	# In the system_branch.branch_name column, we have values such as 2020Q4 and
	# the prefix 'branches' is not included.
	# 
	# But for files, the prefix is included:
	#  freshports.dev=# select * from element_pathname where pathname like '/ports/branches/2019Q3/%' limit 5;
	#   element_id |                    pathname                     
	#  ------------+-------------------------------------------------
	#       960349 | /ports/branches/2019Q3/MOVED
	#       954142 | /ports/branches/2019Q3/Mk
	#       954143 | /ports/branches/2019Q3/Mk/Scripts
	#       954144 | /ports/branches/2019Q3/Mk/Scripts/do-depends.sh
	#       956066 | /ports/branches/2019Q3/Mk/Uses
	# (5 rows)
	# freshports.dev=#
	#
	#
	# So we have the following values:
	#
	# $Updates{branch_git}           - value supplied in XML
	# $Updates{branch_database_name} - for use in system_branch.branch_name
	# $Updates{branch_for_files}     - for use in filenames
	#

	# this converts main to head, and leaves everything else unchanged
	#
	$Updates{branch_for_files} = ConvertGitBranchNameToFreshPortsName($Updates{branch_git});
	
	print "after converting '\$Updates{branch_git}' we have '$Updates{branch_for_files}'\n";
	print "next we need to strip any leading 'branches/' prefix\n";
	$Updates{branch_database_name} = FreshPorts::Branches::stripBranchesToGetBranchName($Updates{branch_for_files});
	print "OS is '$Updates{os}' : branch = '$Updates{branch_git}' for git\n";
	print "OS is '$Updates{os}' : branch = '$Updates{branch_for_files}' for git\n";
	print "OS is '$Updates{os}' : branch = '$Updates{branch_database_name}' for database names\n";

	# We know what branch this message is updating. Let's grab the IDs we will need.
	$SystemID = SystemIDGet($Updates{os}, $self->{dbh});
	if (!defined($SystemID)) {
		$! = 3;
		FreshPorts::Utilities::ReportError('warning', "No SystemID found for OS = '$Updates{os}'", 1)
	}

	if ($Updates{branch_database_name} ne '') {
		# we invoke GetBranchFromPathName to convert branches/2020Q3 to 2020Q3
		$SystemBranchID = SystemBranchIDGetOrCreate($SystemID, $Updates{branch_database_name}, $self->{dbh});
		if (!defined($SystemBranchID)) {
			$! = 4;
			FreshPorts::Utilities::ReportError('warning', "No SystemBranchID found for OS = '$Updates{branch_database_name}'", 1);
		} else {
			$Updates{branch_id} = $SystemBranchID;
		}
	} else {
		FreshPorts::Utilities::Report('warning', "Branch was empty.  Probably imported sources.  Ignoring $inputfile");
		print "Branch was empty.  Probably imported sources.  Ignoring message $inputfile\n";
		die   "Branch was empty.  Probably imported sources.  Ignoring message $inputfile\n";
	}
   
	print "OS is '$Updates{os}' ($SystemID) : branch = $Updates{branch_database_name} ($SystemBranchID)\n";
}


sub handle_update_end {
	#
	# By this point, we have all of the XML information.  We have saved the files
	# to the element table, and the element_revision table has been updated.
	# Now we want to update the Ports subsection of the database based upon
	# the list of files we have.
	#

	my %CommitLogPorts;	# array of port objects touched by this message.
	my $ErrorFound = 0;
	my $FetchOK    = 0;

	#
	# Record the information which is used during Error Notification.
	#
	FreshPorts::CommitterOptIn::RecordCommitMessageID     ($Updates{commit_hash});
	FreshPorts::CommitterOptIn::RecordCommitMessageSubject($Updates{MessageSubject});
	# Originally, I thought this should be $Update{branch_for_files}, but that's not right for commits on head.
	# The XML comes through with '<OS Repo="ports" Id="FreeBSD" Branch="main"/>'
	# 'main' needs to be converted to 'head' which is what FreshPorts uses.
	FreshPorts::CommitterOptIn::RecordCommitBranch        ($Updates{branch_for_files});
	FreshPorts::CommitterOptIn::RecordCommitMessageLog    ($Updates{log});

	if (scalar(@Files) == 0) {
		FreshPorts::Utilities::ReportError('Err', 'No files found in commit ' . $FreshPorts::Config::FreshPortsURL . 'commit.php?message_id=' . $Updates{commit_hash} . '.  This is probably a merge.', 0)
	}

	# some things, we do only for port commits
	if (($Updates{repository} eq $FreshPorts::Config::Repo_PORTS || $Updates{repository} eq $FreshPorts::Config::Repo_PORTS_QUARTERLY)) {

		# XXX - I am quite sure we don't have to do any fetching any more
		if ($fetch_before_refresh) {
			print "oh, the script goes to fetch...\n";
			$FetchOK = FreshPorts::VerifyPort::ScrollToThatCommit($Updates{repository}, $Updates{branch_git}, $Updates{revision});
			if ($FetchOK) {
				$self->notify_observers($FreshPorts::Messages::FilesFetched);
				# we should also refresh our list of categories.
				# this is the list of valid categories according to the repo
				FreshPorts::categories::FetchAll();
			} else {
				print "There was a problem fetching, so I won't be telling the Observer that files have been fetched\n";
			}
		} else {
			$FetchOK = 1;
			print "We are not fetching before refreshing\n";
		}


		%CommitLogPorts = FreshPorts::VerifyPort::SaveChangesToPortsTree($Updates{branch_database_name}, commit_log_id(), \@Files, $self->{dbh}, 'git');

		#
		# commit what we have now, and that starts a new transaction.
		#
		$self->{dbh}->commit();

		print "\n --- end of this update --- \n";

		# we only fetch stuff for the ports repository
		print "this commit is from the '" . $Updates{repository} . "' repository.\n";
	
		# now we should refresh all the ports associated with this commit
		# as each port is refreshed, it will be committed
	
		if ($FetchOK) {
			if ($refresh_ports) {
				#  parameters:                                                        $Repository           $CommitBranch        $CommitLogPortsRef $dbh
				$ErrorFound = FreshPorts::VerifyPort::RefreshAllPortsTouchedByCommit($Updates{repository}, $Updates{branch_git}, \%CommitLogPorts, $self->{dbh});

				if (!$ErrorFound) {
					$ErrorFound = FreshPorts::VerifyPort::RefreshAllSlavePortsOfPortsTouchedByCommit($Updates{repository}, $Updates{branch_git}, \%CommitLogPorts, $self->{dbh}, 'git');
				}

				if (!$ErrorFound) {
					$ErrorFound = FreshPorts::VerifyPort::MarkVulnerableCommits(\%CommitLogPorts, $self->{dbh});
				}

				$self->notify_observers($FreshPorts::Messages::PortsRefreshed, (message_id => $Updates{commit_hash}, CommitLogPorts => \%CommitLogPorts) );

			}
		}
	}

	# we used to just look for errors found in the above code.
	# but now, many underlying functions can record errors.
	# So we introduced the GetErrorCount() function.
	if ($ErrorFound || FreshPorts::CommitterOptIn::GetErrorCount()) {
	    # if we rollback, we lose all the refreshes...
#		$self->{dbh}->rollback();
		print "recording sanity test failure\n";
		$Msg = FreshPorts::CommitterOptIn::GetErrors();
		my $SanityTestFailure = FreshPorts::SanityTestFailures->new( $self->{dbh} );
		$SanityTestFailure->SetCommitLogID(commit_log_id());
		$SanityTestFailure->SetErrorText($Msg);
		my $STFID = $SanityTestFailure->Save();
		print "saved as STFID $STFID\n";
		print "sending NotifyCommitter to $Updates{committer}\n";
		FreshPorts::CommitterOptIn::NotifyCommitter($Updates{committer}, $self->{dbh});
	} else {
		print "No errors found during that commit\n";
	}
	
	$self->{dbh}->commit();
	$self->notify_observers($FreshPorts::Messages::UpdateEnds, 
			(message_id => $Updates{commit_hash}, CommitLogPorts => \%CommitLogPorts, Files => \@Files));

	# we don't clear these values until the end of the update
	undef $Updates{os};
	undef $Updates{branch_git};
	undef $Updates{branch_database_name};
	undef $Updates{branch_for_files};
	undef $Updates{authorName};
	undef $Updates{authorEmail};
	undef $Updates{committerName};
	undef $Updates{committerEmail};
	undef $Updates{committer};
	undef $Updates{dateyear};
	undef $Updates{datemonth};
	undef $Updates{dateday};
	undef $Updates{timehour};
	undef $Updates{timeminute};
	undef $Updates{timesecond};
	undef $Updates{timezone};
	undef $Updates{log};
	undef $Updates{respository};

	undef $Updates{messageyear};
	undef $Updates{messagemonth};
	undef $Updates{messageday};
	undef $Updates{messagehour};
	undef $Updates{messageminute};
	undef $Updates{messagesecond};
	undef $Updates{messagezone};
	undef $Updates{MessageTo};

	undef $Updates{MessageSubject};

	undef $Updates{commit_hash};
	undef $Updates{commit_hash_short};
	undef $Updates{repo};
	
	if ($ErrorFound) {
		Set_Rollback_Needed();
	}

	undef $dbh;
}

sub handle_updates_end {
	print "\n\n *** end of all updates *** \n";
	$self->notify_observers($FreshPorts::Messages::ProcessingDone);
}

sub FileActionValid($) {
	my $FileAction = shift;

	return $ValidFileActions{$FileAction};
}

sub ConvertGitBranchNameToFreshPortsName($) {
	my $GitBranch = shift;
	
	#
	# this converts main to head
	# if there is no conversion value, use what we were given.
	#
	my $Branch =  $BranchConversions{$GitBranch};

	if (!defined($Branch)) {
		$Branch = $GitBranch;
	}

	return $Branch;
}


sub ConvertFilePath($) {
	my $FilePath = shift;

	#
	# some files are not what they appear
	# in particular CVSROOT needs to be altered.
	# FreeBSD actually uses several repositories.
	# Each has a CVSROOT.  To differentiate, we append
	# the repo name to the CVSROOT directory, if there is a repo name.
	#

	my $FilePathNew = $FilePath;

	if ($FilePath =~ /^CVSROOT\/(.*)/) {
		if ($Updates{repository}) {
			$FilePathNew = 'CVSROOT-' . $Updates{repository} . '/' . $1;
		}
	}

	print "ConvertFilePath: '$FilePath' => '$FilePathNew'\n";

	return $FilePathNew;
}

sub GetDB_RepoPrefix($) {
#
# Given the repo name, obtain the root prefix for the database path
#

	my $RepoName = shift;
	
	if (!defined($RepoName)) {
		die('no value set for incoming RepoName');
	}
	
	my $myRepoPrefix = '';

	my %KnownRepos = (
		$FreshPorts::Config::Repo_DOC             => $FreshPorts::Config::DB_Root_Prefix_DOC,
		$FreshPorts::Config::Repo_PORTS           => $FreshPorts::Config::DB_Root_Prefix_PORTS,
		$FreshPorts::Config::Repo_PORTS_QUARTERLY => $FreshPorts::Config::DB_Root_Prefix_PORTS_QUARTERLY,
		$FreshPorts::Config::Repo_SRC             => $FreshPorts::Config::DB_Root_Prefix_SRC,
	);
	
	while (my ($myRepoName, $DB_RepoPrefix) = each %KnownRepos)
	{
		if ($myRepoName eq $RepoName)
		{
			$myRepoPrefix = $DB_RepoPrefix;
			last;
		}
	}
	
	if ($myRepoPrefix eq '')
	{
	   die('unknown RepoName: ' . $RepoName);
	}
	
	return $myRepoPrefix;
}

sub ConvertRepoLabelToGitRepoName($) {
#
# Given the repo name label from XML, obtain the FreeBSD repo name.
#

	my $Repo_XML_Label = shift;
	
	if (!defined($Repo_XML_Label)) {
		die('no value set for incoming Repo_XML_Label');
	}
	
	my $myRepoPrefixGitRepoName = $FreshPorts::Constants::RepoLabelsToGitRepoNames{$Repo_XML_Label};

	if (!defined($myRepoPrefixGitRepoName)) {
		die("'$Repo_XML_Label' was not found in \$FreshPorts::Constants::RepoLabelsToGitRepoNames\n");
	}
	
	return $myRepoPrefixGitRepoName;
}

sub handle_file_end {
	# for svn we have:
	#      <FILE Action="Modify" Revision="512343" Path="head/net/tightvnc/Makefile"></FILE>
	#      <FILE Action="Modify" Revision="512267" Path="branches/2019Q3/cad/geda/Makefile"></FILE>
	# for git we have
	#       <FILE Action="Modify" Path="net-mgmt/unifi5/Makefile"/>
	#
	# the git path must be prefixed with ports/head/, or perhaps ports/branches/2021Q2
	# With subversion, it is prefixed with only ports/

	my $FileAction     = $Updates{FileAction};
	my $FilePath       = $Updates{FilePath};
	
	# with git, we have no file revision. Let's use the hash.
	# same with MessageId
	$Updates{FileRevision} = $Updates{commit_hash};
	my $FileRevision       = $Updates{FileRevision};
	
	print "commit_hash           = '$Updates{commit_hash}'\n";
	print "Updates{FileRevision} = '$Updates{FileRevision}'\n";
	print "FileRevision          = '$FileRevision'\n";
	
	my $DB_Root_Prefix = GetDB_RepoPrefix($Updates{repository});
	my $fileaction;    # the value obtained from the hash array
	                   # and which will be stored into the database.

	# sometimes, we see . in pathnames.
	# e.g 201205262318.q4QNI7EZ020858@repoman.freebsd.org
	#     201205262318.q4QNI7EZ020858@repoman.freebsd.org
	#     201205262324.q4QNOLJF021342@repoman.freebsd.org
	# e,g ports/./devel/kdevelop-kde4/Makefile
	# this step reduces those pathnames to something we can use
	
	$FilePath =~ s#/\./#/#;

	my $ElementAdded	= 0;
	my $NewRevision		= 0;
	my $element;
	my $element_id;
	my $filename;
	# This is where we add in the repo name to the path
	# At one time, I think, $Updates{branch_for_files} was to be either head or branches/2021Q2 (or example).
	# As of 2021.06.20, it is either head or 2021Q2 (no branches).
	# I think the best thing to do is to check $Updates{branch_for_files} here and add in branches when required.
	if ($Updates{branch_for_files} eq $FreshPorts::Constants::HEAD) {
		$filename = $DB_Root_Prefix . '/' .          $Updates{branch_for_files} . '/' . $FilePath;
	} else {
		$filename = $DB_Root_Prefix . '/branches/' . $Updates{branch_for_files} . '/' . $FilePath;
	}	
	my $revisionname = $FileRevision;
	my $commit_log_element;
	

	print "File = [$FileAction : $filename";

	#
	# we only get a FileRevision for Modify and Add
	#

	if ($FileAction eq $FreshPorts::Constants::ADD || $FileAction eq $FreshPorts::Constants::MODIFY) {
		$NewRevision = 1;
		print " : $FileRevision";
	}

	print "]\n";

	$fileaction = FileActionValid($FileAction);
	if (!$fileaction) {
		$! = 5;
		FreshPorts::Utilities::ReportError('warning', "invalid file action ('$FileAction') found in $inputfile", 1);
	}

	print "FileActionValid ==> " . $fileaction . "\n";

	if (!defined(commit_log_id())) {
		return;
	}

	# grab the element corresponding to this filename.
	$element = FreshPorts::Element->new($self->{dbh});
	
	# each file is in a repo.
	# each repo is in the database under a different directory.
	# therefore, prefix each file with the repo root path
	$element->{pathname} = $filename;
	$element_id = $element->FetchByName();

	# if we didn't find it, we add it.
	if (!defined($element_id)) {
		print "We didn't find $FilePath in the database\n";
		# add the element to the tree
		$element->{directory_file_flag} = 'F';

		#
		# sometimes we find out about an element being removed
		# before we've added it to the tree...
		#

		if ($FileAction eq $FreshPorts::Constants::DELETE) {
			print "we will add it as a deleted item\n";
			$element->{status} = $FreshPorts::Element::Deleted;
		}
		$element_id = $element->save();

		#
		# and now fetch it back so we have all the correct values.
		# (e.g. parent_id)
		#
		$element->FetchByName();
		$ElementAdded = 1;
	} else {
		# sometimes the status is wrong.  This is where we correct it.
		if ($element->{status} eq $FreshPorts::Element::Active) {
			if ($FileAction eq $FreshPorts::Constants::DELETE) {
				$element->{status} = $FreshPorts::Element::Deleted;
				$element->save();
			}
		} else {
			if ($element->{status} eq $FreshPorts::Element::Deleted) {
				if ($FileAction eq $FreshPorts::Constants::MODIFY || $FileAction eq $FreshPorts::Constants::ADD) {
					$element->{status} = $FreshPorts::Element::Active;
					$element->save();
				}
			} else {
				FreshPorts::Utilities::ReportError('warning', "Unknown element->status found.", 1);
			}
		}
	}

	#
	# if we failed to created an element, we should stop
	#
	if (!defined($element_id)) {
		$! = 6;
		FreshPorts::Utilities::ReportError('warning', "sorry, but I should have had an element_id for '$filename', but I didn't.", 1);
	}

	#
	# the ElementRevision entry must always exist, regardless
	# of what we are doing.  If we are deleting an item, it may
	# have not yet been added.  This may be because of mail
	# messages being received out of order or because of items
	# not on file because their creation pre-dates this database.
	#
	if (ElementRevisionExists($element_id, $revisionname, $self->{dbh})) {
		print "That element revision already exists; not adding it\n";
	} else {
		ElementRevisionInsert($element_id, $revisionname, $self->{dbh});
	}

	print "saving commit_log_element\n";

	print "\$FreshPorts::Constants::commit_log_seq='$FreshPorts::Constants::commit_log_seq'\n";
	print "\$FreshPorts::Constants::ports_seq='$FreshPorts::Constants::ports_seq'\n";
	print "\$FreshPorts::Constants::commit_log_elements_seq='$FreshPorts::Constants::commit_log_elements_seq'\n";

	$commit_log_element = FreshPorts::CommitLogElement->new($self->{dbh});
	$commit_log_element->{commit_log_id} = commit_log_id();
	$commit_log_element->{element_id}    = $element_id;
	$commit_log_element->{revision_name} = $revisionname;
	$commit_log_element->{change_type}   = $fileaction;

	$commit_log_element->save();

	#
	# when adding new elements, be sure to record the new revision name.
	#
	if ($NewRevision) {
		SystemBranchElementInsert($SystemBranchID, $element_id, $revisionname, $self->{dbh});
	}
	
	#
	# accumulate a list of files which will be updated later
	#
	print 'pushing the following onto @Files' . "\n";
	print "FileAction='$FileAction'\n";
	print "FilePath='$filename'\n";
	print "FileRevision='$FileRevision'\n";
	print "commit_log_element->{id}='" . $commit_log_element->{id} . "'\n";
	print "element_id='$element_id'\n";
	push @Files, [$FileAction, $filename, $FileRevision, $commit_log_element->{id}, $element_id];

	$self->notify_observers($FreshPorts::Messages::FileUpdate, (FileAction => $FileAction, FilePath => $filename, FileRevision => $FileRevision, Repository => $Updates{repository}) );
	

	undef $Updates{FileAction};
	undef $Updates{FilePath};
	undef $Updates{FileRevision};
}

sub ElementRevisionExists($;$;$) {
	my $ElementID    = shift;
	my $RevisionName = shift;
	my $dbh          = shift;

	my $sth;
	my $sql;
	my @row;

	# quote everything going to the database
	my $QuotedRevisionName = $dbh->quote($RevisionName);
	$sql = "select count(*) from element_revision where element_id = $ElementID and revision_name = $QuotedRevisionName";
	$sth = $dbh->prepare($sql);
	if (!$sth->execute())  {
		FreshPorts::Utilities::ReportError('warning', "Could not execute sql", 1);
	}
	@row = $sth->fetchrow_array();   
	$sth->finish();
	
	undef $dbh;

	return $row[0];
}


sub ElementRevisionInsert($;$;$) {
	my $ElementID    = shift;
	my $RevisionName = shift;
	my $dbh          = shift;

	my $sth;
	my $sql;

	# quote everything going into the database
	my $QuotedRevisionName = $dbh->quote($RevisionName);

	$sql = "insert into element_revision (element_id, revision_name) values ($ElementID, $QuotedRevisionName)";
 
	print "sql = '$sql'\n";
 
	if (!$debug) {
		$sth = $dbh->prepare($sql);
		if (!$sth->execute) {
			FreshPorts::Utilities::ReportError('warning', "Could not execute sql " . $dbh->err . " " . $dbh->errstr, 1);
		}

		$sth->finish();
	}

	undef $dbh;
}

sub handle_message_end {
	# we have the end of the main part of the mail message.  All that's left are the files.
	# let's commit this stuff so we have a commit_log_id.

	$Updates{revision} = $Updates{commit_hash};

	# But for the first edition of FreshPorts2,
	# we only want ports. nothing but ports.
	# The criteria for that is the subject must start with
	# "cvs commit: ports/".

	print "OS                   = [$Updates{os}]\n";
	print "Branch git           = [$Updates{branch_git}]\n";
	print "branch_database_name = [$Updates{branch_database_name}]\n";
	print "branch_for_files     = [$Updates{branch_for_files}]\n";
	print "Committer            = [$Updates{committer}]\n";
	print "Date                 = [" . sprintf "%04u/%02u/%02u %02u:%02u:%02u %s", $Updates{dateyear}, $Updates{datemonth}, $Updates{dateday}, $Updates{timehour}, $Updates{timeminute}, $Updates{timesecond}, $Updates{timezone} . "]\n";
	if (defined($Updates{repository})) {
		print "Repository     = [$Updates{repository}]\n";
	} else {
		print "Repository     = not defined, perhaps an older commit.\n";
	}

	if (defined($Updates{revision})) {
		print "Revision       = [$Updates{revision}]\n";
	} else {
		print "Revision       = not defined, perhaps an older commit.\n";
	}

	print "MessageId      = [$Updates{commit_hash}]\n";
	print "short hash     = [$Updates{commit_hash_short}]\n";

	print "Subject        = [$Updates{MessageSubject}]\n";
	print "Log            = [$Updates{log}]\n";
	# use this information to update the database
	print "into handle_message_end, let's save that message now!\n\n";

	# First thing we must do, is tell the database what Branch to use...
	# XXX why does this not use branches::SetBranchInDB() ?
	my $sql = 'select freshports_branch_set(' . $self->{dbh}->quote($Updates{branch_database_name}) . ')';
	my $sth = $self->{dbh}->prepare($sql);
	if (!$sth->execute())  {
		FreshPorts::Utilities::ReportError('warning', "Could not set branch", 1);
	}

	if (!$debug) {
		$commit_log_id = SaveUpdateToDB();
	}

	# Let's found avoid: DBI::db=HASH(0x348838f41618)->disconnect invalidates 1 active statement handle (either destroy statement handles or
	# call finish on them before disconnecting) at /usr/local/lib/perl5/site_perl/FreshPorts/xml_munge_git.pm line 902.
	# if no commit log id is returned.
	$sth->finish();

	if (!defined(commit_log_id())) {
		print "no commit id returned.  we'll just exit now shall we?\n";
		# We are exiting here, let's destroy this and avoid:
		# DBI dr handle 0x340f309447c8 cleared whilst still active during global destruction
		$self->{dbh}->disconnect();		
		exit 0;
	}
}

sub handle_committer_end {
    # extract the commiter (user)  from the email address
    my $address = Email::Address::XS->parse($Updates{committerEmail});
    $Updates{committer} = $address->user();
    
    print "found Committer= [$Updates{committer}]\n";
}

sub handle_author_end {
    # see commit 9bae4ce661c59be88fec89b2531148e36dd1a23e
    # re https://cgit.freebsd.org/src/commit/?id=9bae4ce661c59be88fec89b2531148e36dd1a23e
    # AuthorEmail="danq1222_gmail.com"
    # Se we print AuthoName, not the user as is done with committer.
    print "found Author= [";
    if (defined($Updates{authorName})) {
    	print $Updates{authorName};
    }
    print "]\n";
}

sub handle_messageto_end {
	#
	# this function is called several times.
	#

	if (defined($Updates{MessageToAll})) {
		print "...$Updates{MessageTo}\n";
		$Updates{MessageToAll} .= ", " . $Updates{MessageTo};
	} else {
		print "***$Updates{MessageTo}\n";
		$Updates{MessageToAll} = $Updates{MessageTo};
	}
	undef $Updates{MessageTo};

	print "found To       = [$Updates{MessageToAll}]\n";
}

sub SaveUpdateToDB {
	my $sth;
	my $sql;
	my @row;
	my $message_date;

	my $temp;

	my $commit_log = FreshPorts::Commit_Log->new($self->{dbh});
	$commit_log->setRepo($FreshPorts::Constants::Git);

	print "xml_munge_git.pm::SaveUpdateToDB --- start\n";

	my $message_id = id();

	my $existing_commit_id = GetExistingMessageID($message_id, $self->{dbh});

	if (defined($existing_commit_id)) {
		FreshPorts::Utilities::ReportError('warning', "message $message_id has already been added to the database", 0);

		if ($overwrite) {
			FreshPorts::Utilities::ReportError('warning', "message $message_id being removed", 0);

			# delete that message
			$sql = 'delete from commit_log where message_id = ' .  $self->{dbh}->quote($message_id);
			$sth = $self->{dbh}->prepare($sql);
			if (!$sth->execute) {
				FreshPorts::Utilities::ReportError('warning', "Could not execute SQL $sql $self->{dbh}->err", 1);
			}
			$sth->finish();
		} else {
			my $nullvalue;
			return $nullvalue;
		}
	}

	$message_date = sprintf "%04u/%02u/%02u %02u:%02u:%02u %s", 
		$Updates{dateyear}, $Updates{datemonth},  $Updates{dateday}, 
		$Updates{timehour}, $Updates{timeminute}, $Updates{timesecond}, 
		$Updates{timezone};

	my $message_subject = $Updates{MessageSubject};

	my $date_added = "now()";
	if (defined($Updates{DateAdded})) {
		$date_added = $Updates{DateAdded};
	}

	my $commit_date     = sprintf "%04u/%02u/%02u %02u:%02u:%02u %s", 
							$Updates{dateyear}, $Updates{datemonth}, $Updates{dateday}, 
							$Updates{timehour}, $Updates{timeminute}, $Updates{timesecond}, 
							$Updates{timezone};

	my $committer   = $Updates{committer};
	my $description = $Updates{log};
	my $revision    = $Updates{revision};

	# declare, assign, and never use. Trying to avoid this error by delcaring it:
	# Name "FreshPorts::XML_Munge_git::rest" used only once: possible typo at xml_munge_git.pm line 990.
	my $rest;
   
	# sometimes the committer field looks like: scheidell (ports committer)
	# this takes the stuff before the first blank and we assume that is the committer id.
	# the rest, we discard, ignore, and toss away.  So sad.
	($committer, $rest) = split /\s+\W+\s*/, $committer, 2;

	$commit_log->{message_id}        = $message_id;
	$commit_log->{message_date}      = $message_date;
	$commit_log->{message_subject}   = $message_subject;
	$commit_log->{date_added}        = $date_added;
	$commit_log->{commit_date}       = $commit_date;
	$commit_log->{committer}         = $committer;
	$commit_log->{committer_name}    = $Updates{committerName};
	$commit_log->{committer_email}   = $Updates{committerEmail};
	$commit_log->{author_name}       = $Updates{authorName};
	$commit_log->{author_email}      = $Updates{authorEmail};
	$commit_log->{description}       = $description;
	$commit_log->{system_id}         = $SystemID;
	$commit_log->{commit_hash_short} = $Updates{commit_hash_short};
	$commit_log->{repo}	             = ConvertRepoLabelToGitRepoName($Updates{repository});
	$commit_log->{revision}          = $revision;

	#
	# MessageEncodingLosses is new.
	# older templates do not contain it
	# commit_log will contain an appropriate default value.
	#
	if (defined($Updates{MessageEncodingLosses})) {
		$commit_log->{encoding_losses} = $Updates{MessageEncodingLosses};
	}

	$id = $commit_log->save();

	print "saving commit_log <-> branch information\n";	
	my $commit_log_branches = FreshPorts::Commit_Log_Branches->new($self->{dbh});
	$commit_log_branches->{commit_log_id} = $id;
	$commit_log_branches->{branch_id}     = $Updates{branch_id};
	$commit_log_branches->save();	

	print "we have saved with id = '$id'\n";

	$self->notify_observers($FreshPorts::Messages::CommitSaved, (commit_log_id => $id, message_id => $message_id) );

	print "xml_munge_git.pm::SaveUpdateToDB --- finish\n";

	return $id;
}

sub GetExistingMessageID($;$) {
	my $message_id = shift;
	my $dbh        = shift;
	my $sth;
	my $sql;
	my @row;
   
	$sql = "select id from commit_log where message_id = " . $dbh->quote($message_id);

	print "GetExistingMessageID => sql=$sql\n";
   
	$sth = $dbh->prepare($sql);
	if (!$sth->execute) {
		FreshPorts::Utilities::ReportError('warning', "Could not execute SQL $sql", 1);
	}

	@row = $sth->fetchrow_array();
   
	$sth->finish();

	undef $dbh;
   
	return $row[0];
}

sub SystemBranchIDGetOrCreate($;$;$) {   
	# obtain the system_branch_id for the given version of this system
	my $system_id	= shift;
	my $BranchName	= shift;
	my $dbh         = shift;

	my $sql;
	my $sth;
	my @row;

	my $SystemBranchID;

	#
	# we want to remove any leading 'branches/' from the string.
	# we want just 2020Q3, for example
	#
	
	my $branch_name = FreshPorts::Branches::stripBranchesToGetBranchName($BranchName);
	
	print "SystemBranchIDGetOrCreate has converted '$BranchName' to '$branch_name' which will be used in the database\n";

	$sql = "select SystemBranchIDGet($system_id, " . $dbh->quote($branch_name) . ")";

	print "sql = '$sql'\n";

	$sth = $dbh->prepare($sql);
	if (!$sth->execute) {
		FreshPorts::Utilities::ReportError('warning', "Could not execute SQL $sql", 1);
	}

	@row = $sth->fetchrow_array();
	
	$sth->finish();

	$SystemBranchID = $row[0];
	if (!defined($SystemBranchID)) {
		FreshPorts::Utilities::ReportError('warning', "creating new Branch $branch_name", 0);

		$SystemBranchID = FreshPorts::Database::GetNextValue($FreshPorts::Constants::system_branch_seq, $dbh);
		$sql = "insert into system_branch (id, system_id, branch_name) values " .
					" ($SystemBranchID, $SystemID, " . $dbh->quote($branch_name) . ")";

		$sth = $dbh->prepare($sql);
		if (!$sth->execute) {
			FreshPorts::Utilities::ReportError('warning', "Could not execute SQL $sql", 1);
		}
		$sth->finish();
	}

	undef $dbh;

	return $SystemBranchID;
}

sub SystemIDGet($;$) {
	# obtain the system_branch_id for the given version of this system
	my $system_name = shift;
	my $dbh         = shift;

	my $sql;
	my $sth;
	my @row;

	my $quoted_system_name = $dbh->quote($system_name);
	$sql = "select SystemIDGet($quoted_system_name)";
   
	print "sql = '$sql'\n";

	$sth = $dbh->prepare($sql);
	$sth->execute ||
		FreshPorts::Utilities::ReportError('warning', "Could not execute SQL $sql ... maybe invalid?", 1);

	@row = $sth->fetchrow_array();

	$sth->finish();

	undef $dbh;

	return $row[0];
}

sub SystemBranchElementInsert($;$;$;$) {
	my $SystemBranchID = shift;
	my $ElementID      = shift;
	my $RevisionName   = shift;
	my $dbh            = shift;

	my $sth;
	my $sql;
	my @row;

	my $QuotedRevisionName = $dbh->quote($RevisionName);
	$sql = "select ElementTagSet($SystemBranchID, $ElementID, $QuotedRevisionName)";

	print "sql = '$sql'\n";

	if (!$debug) {
		$sth = $dbh->prepare($sql);
		$sth->execute ||
				FreshPorts::Utilities::ReportError('warning', "Could not execute SQL $sql ... maybe invalid?", 1);

		$sth->finish();
	}

	undef $dbh;
}

sub id {
	# this will get the message id once we know it.
	# implemented only for observable class

	return $Updates{commit_hash};
}

sub repo {
	# what repo are we updating?
	# this is important for CVSROOT.  Each commit will refer to CVSROOT, yet the actual file being updated will be in CVSROOT-ports
	if (defined($Updates{repository})) {
		return $Updates{repository};
	} else {
		return '';
	}
}

sub commit_log_id {
	# this will get the message id once we know it.
	# implemented only for observable class

	return $commit_log_id;
}

sub Set_Rollback_Needed() {
	$_RollbackNeeded = 1;
}


1;
