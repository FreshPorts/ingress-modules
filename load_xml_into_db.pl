#!/usr/bin/perl -w
#
# $Id: load_xml_into_db.pl,v 1.46.2.1 2002-04-01 22:52:06 dan Exp $
#
# Copyright (c) 2001-2002 DVL Software
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

#we make a great deal of use of a global variable Updates.  We should fix that up.
# use strict;

push (@INC, '~/scripts');

use lib "$ENV{HOME}/scripts";

require Sys::Syslog;

use element;
use verifyport;
use config;
use constants;
use commit_log;
use commit_log_element;
use db_utils;
use database;
use utilities;
use housekeeping;
use cache;

use XML::Node;
use DBI;

my $commit_log_id			= 0;
my $debug					= 0;
my $overwrite				= 0;
my $refresh_ports			= 1;	# refresh any ports touched by a commit
my $fetch_before_refresh	= 1;	# by default, we fetch files from cvs 
									# before refreshing from them

my $SystemID;			# the system id for this update.  Usually 'FreeBSD' => 1
my $SystemBranchID;		# the system version id for this update.  Usually 'HEAD' => 1

my $dbh;

my @Files;				# files affected by this commit

#
# a file can be added to the repository, deleted (removed) from the repository,
# or modified in the repository.
#
my %ValidFileActions = (	$FreshPorts::Constants::ADD		=> "A",
							$FreshPorts::Constants::REMOVE	=> "R",
							$FreshPorts::Constants::MODIFY	=> "M");


FreshPorts::Utilities::InitSyslog();

my %Updates;


&main;
exit;

#####
# Main Processing Routine
##### 

sub main {

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
			}

			if ($ARGV[$i] eq '-O') {
				print "overwriting....\n";
				$overwrite = 1;
			}

			if ($ARGV[$i] eq '-r') {
				# useful if we only want to use
				# what's on disk.
				print "not fetching before refresh....\n";
				$fetch_before_refresh = 0;
			}

			if ($ARGV[$i] eq '-R') {
				# do not refresh the ports.  just process the commit
				print "not refreshing at all....\n";
				$refresh_ports = 0;
			}
		}

	} else {
		print "USAGE : $0 INPUTFILE [-D] [-O] [-r] [-R] <-D means debug, don't actually update the database> <-O means overwrite any existing message id>\n";
		exit 1;
	}

	SetupParser($p);

	print "Processing file [$inputfile]...\n";

	print "dbname = $FreshPorts::Config::dbname\n";

	$dbh = FreshPorts::Database::GetDBHandle();
	if ($dbh->{Active}) {

		$p->parsefile($inputfile);

# hmmm, this might be a good way to debug...
# issue a rollback after each attempt...
#
#		$dbh->rollback();
		$dbh->commit();

		$dbh->disconnect();
	}
}

sub SetupParser($) {
	my $p = shift;

	$p->register(">UPDATES",								"start" => \&handle_updates_start);
	$p->register(">UPDATES>UPDATE",							"start" => \&handle_update_start);

	$p->register(">UPDATES>UPDATE>DATE:Year",				"attr" => \$Updates{dateyear});
	$p->register(">UPDATES>UPDATE>DATE:Month",				"attr" => \$Updates{datemonth});
	$p->register(">UPDATES>UPDATE>DATE:Day",				"attr" => \$Updates{dateday});

	$p->register(">UPDATES>UPDATE>TIME:Hour",				"attr" => \$Updates{timehour});
	$p->register(">UPDATES>UPDATE>TIME:Minute",				"attr" => \$Updates{timeminute});
	$p->register(">UPDATES>UPDATE>TIME:Second",				"attr" => \$Updates{timesecond});
	$p->register(">UPDATES>UPDATE>TIME:Timezone",			"attr" => \$Updates{timezone});

	$p->register(">UPDATES>UPDATE>OS:Id",					"attr" => \$Updates{os});
	$p->register(">UPDATES>UPDATE>OS:Branch",				"attr" => \$Updates{branch});
	$p->register(">UPDATES>UPDATE>OS",						"end"  => \&handle_os_end);
        
	$p->register(">UPDATES>UPDATE>LOG",						"char" => \$Updates{log});

	$p->register(">UPDATES>UPDATE>PEOPLE>UPDATER:Handle",	"attr" => \$Updates{committer});
	$p->register(">UPDATES>UPDATE>PEOPLE>UPDATER",			"end"  => \&handle_updater_end);

	$p->register(">UPDATES>UPDATE>MESSAGE:Id",				"attr" => \$Updates{MessageId});

	$p->register(">UPDATES>UPDATE>MESSAGE:Subject",			"attr" => \$Updates{MessageSubject});


	$p->register(">UPDATES>UPDATE>MESSAGE>DATE:Year",		"attr" => \$Updates{messageyear});
	$p->register(">UPDATES>UPDATE>MESSAGE>DATE:Month",		"attr" => \$Updates{messagemonth});

	$p->register(">UPDATES>UPDATE>MESSAGE>DATE:Day",		"attr" => \$Updates{messageday});

	$p->register(">UPDATES>UPDATE>MESSAGE>TIME:Hour",		"attr" => \$Updates{messagehour});
	$p->register(">UPDATES>UPDATE>MESSAGE>TIME:Minute",		"attr" => \$Updates{messageminute});
	$p->register(">UPDATES>UPDATE>MESSAGE>TIME:Second",		"attr" => \$Updates{messagesecond});
	$p->register(">UPDATES>UPDATE>MESSAGE>TIME:Timezone",	"attr" => \$Updates{messagezone});

	$p->register(">UPDATES>UPDATE>MESSAGE>TO:Email",		"attr" => \$Updates{MessageTo});
	$p->register(">UPDATES>UPDATE>MESSAGE>TO",				"end"  => \&handle_messageto_end);

	$p->register(">UPDATES>UPDATE>MESSAGE",					"end"  => \&handle_message_end);

	$p->register(">UPDATES>UPDATE>FILES>FILE:Path",			"attr" => \$Updates{FilePath});
	$p->register(">UPDATES>UPDATE>FILES>FILE:Action",		"attr" => \$Updates{FileAction});
	$p->register(">UPDATES>UPDATE>FILES>FILE:Revision",		"attr" => \$Updates{FileRevision});

	$p->register(">UPDATES>UPDATE>FILES>FILE",				"end"  => \&handle_file_end);


	$p->register(">UPDATES>UPDATE",							"end" => \&handle_update_end);
	$p->register(">UPDATES",								"end" => \&handle_updates_end);
}

sub handle_updates_start
{
   print "\n\n *** start of all updates ***\n";
}

sub handle_update_start
{
	print "\n --- start of an update --- \n";

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

	print "OS is '$Updates{os}' : branch = '$Updates{branch};\n";

	# We know what branch this message is updating. Let's grab the IDs we will need.
	$SystemID = SystemIDGet($Updates{os}, $dbh);
	if (!defined($SystemID)) {
		$! = 3;
		FreshPorts::Utilities::ReportError('warning', "No SystemID found for OS = '$Updates{os}'", 1)
	}

	if ($Updates{branch} ne '') {  
		$SystemBranchID = SystemBranchIDGetOrCreate($SystemID, $Updates{branch}, $dbh);
		if (!defined($SystemBranchID)) {
			$! = 4;
			FreshPorts::Utilities::ReportError('warning', "No SystemBranchID found for OS = '$Updates{branch}'", 1);
		}
	} else {
		Sys::Syslog::syslog('warning', "Branch was empty.  Probably imported sources.  Ignoring $inputfile");
		print "Branch was empty.  Probably imported sources.  Ignoring message $inputfile\n";
		die   "Branch was empty.  Probably imported sources.  Ignoring message $inputfile\n";
	}
   
	print "OS is '$Updates{os}' ($SystemID) : branch = $Updates{branch} ($SystemBranchID)\n";
}


sub handle_update_end
{
	#
	# By this point, we have all of the XML information.  We have saved the files
	# to the element table, and the element_revision table has been updated.
	# Now we want to update the Ports subsection of the database based upon
	# the list of files we have.

	my %CommitLogPorts;	# array of port objects touched by this message.

	%CommitLogPorts = FreshPorts::VerifyPort::SaveChangesToPortsTree($commit_log_id, \@Files, $dbh);
	$dbh->commit();

	print "\n --- end of this update --- \n";

    my $commit_date = sprintf "%04u-%02u-%02u", $Updates{dateyear}, $Updates{datemonth}, $Updates{dateday};

	# we don't clear these values until the end of the update
	undef $Updates{os};
	undef $Updates{branch};
	undef $Updates{committerAll};
	undef $Updates{dateyear};
	undef $Updates{datemonth};
	undef $Updates{dateday};
	undef $Updates{timehour};
	undef $Updates{timeminute};
	undef $Updates{timesecond};
	undef $Updates{timezone};
	undef $Updates{log};

	undef $Updates{messageyear};
	undef $Updates{messagemonth};
	undef $Updates{messageday};
	undef $Updates{messagehour};
	undef $Updates{messageminute};
	undef $Updates{messagesecond};
	undef $Updates{messagezone};
	undef $Updates{MessageTo};

	undef $Updates{MessageSubject};

	undef $Updates{MessageId};
	undef $Updates{MessageToAll};
	undef $Updates{MessageSubject};

	# now we should refresh all the ports associated with this commit
	# as each port is refreshed, it will be committed

	if ($refresh_ports) {
		FreshPorts::VerifyPort::RefreshAllPortsTouchedByCommit(\%CommitLogPorts, $fetch_before_refresh, $dbh);
	}

	if (scalar(keys %CommitLogPorts)) {
		print "adding that commit date to the daily summary refresh list\n";
		FreshPorts::Cache::DailySummaryDateAdd($commit_date, $dbh)
	} else {
		print "that was not a port, so not adding to daily summary refresh list\n";
	}
}

sub handle_updates_end {
	print "\n\n *** end of all updates *** \n";

}

sub FileActionValid($) {
   my $FileAction = shift;

   return $ValidFileActions{$FileAction};
}


sub handle_file_end
{
	my $FileAction		= $Updates{FileAction};
	my $FilePath		= $Updates{FilePath};
	my $FileRevision	= $Updates{FileRevision};
	my $fileaction;		# the value obtained from the hash array
						# and which will be stored into the database.

	my $ElementAdded	= 0;
	my $NewRevision		= 0;
	my $element;
	my $element_id;
	my $filename		= $FilePath;
	my $revisionname	= $FileRevision;
	my $commit_log_element;


	print "File = [$FileAction : $FilePath";

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

	if (!defined($commit_log_id)) {
		return;
	}

	# grab the element corresponding to this filename.
	$element = FreshPorts::Element->new($dbh);
	$element->{pathname} = $filename;
	$element_id = $element->FetchByName();

	if (!defined($element_id)) {
		# add the element to the tree
		$element->{directory_file_flag} = 'F';

		#
		# sometimes we find out about an element being removed
		# before we've added it to the tree...
		#

		if ($FileAction eq $FreshPorts::Constants::REMOVE) {
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
			if ($FileAction eq $FreshPorts::Constants::REMOVE) {
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
	# messages being recieved out of order or because of items
	# not on file because their creation pre-dates this database.
	#
	if (!ElementRevisionExists($element_id, $revisionname, $dbh)) {
		ElementRevisionInsert($element_id, $revisionname, $dbh);
	}

	print "saving commit_log_element\n";

print "$FreshPorts::Constants::commit_log_seq\n";
print "$FreshPorts::Constants::ports_seq\n";
print "$FreshPorts::Constants::commit_log_elements_seq\n";

	$commit_log_element = FreshPorts::CommitLogElement->new($dbh);
	$commit_log_element->{commit_log_id}	= $commit_log_id;
	$commit_log_element->{element_id}		= $element_id;
	$commit_log_element->{revision_name}	= $revisionname;
	$commit_log_element->{change_type}		= $fileaction;

	$commit_log_element->save();

	#
	# when adding new elements, be sure to record the new revision name.
	#
	if ($NewRevision) {
		SystemBranchElementInsert($SystemBranchID, $element_id, $revisionname, $dbh);
	}

	#
	# accumulate a list of files which will be updated later
	#

	push @Files, [$FileAction, $FilePath, $FileRevision, $commit_log_element->{id}];

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
}

sub handle_message_end {
   # we have the end of the main part of the mail message.  All that's left are the files.
   # let's commit this stuff so we have a commit_log_id.

   # But for the first edition of FreshPorts2,
   # we only want ports. nothing but ports.
   # The criteria for that is the subject must start with
   # "cvs commit: ports/".

   print "OS             = [$Updates{os}]\n";
   print "Branch         = [$Updates{branch}]\n";
   print "Committer      = [$Updates{committerAll}]\n";
   print "Date           = [" . sprintf "%04u/%02u/%02u %02u:%02u:%02u %s", $Updates{dateyear}, $Updates{datemonth}, $Updates{dateday}, $Updates{timehour}, $Updates{timeminute}, $Updates{timesecond}, $Updates{timezone} . "]\n";
   print "Log            = [$Updates{log}]\n";

   print "MessageId      = [$Updates{MessageId}]\n";

   print "MessageDate    = [" . sprintf "%04u/%02u/%02u %02u:%02u:%02u %s", $Updates{messageyear}, $Updates{messagemonth}, $Updates{messageday}, $Updates{messagehour}, $Updates{messageminute}, $Updates{messagesecond}, $Updates{messagezone} . "]\n";
   print "MessageTo      = [$Updates{MessageToAll}]\n";
   print "MessageSubject = [$Updates{MessageSubject}]\n";

#	we will now process all commits, not just ports commits
#
#   if (!($Updates{MessageSubject} =~ m/ports/)) {
#      print "not a ports tree commit.  we'll just exit now shall we?\n";
#      exit 7;
#   }

   # use this information to update the database
   print "into handle_message_end, let's save that message now!\n\n";

   if (!$debug) {
      $commit_log_id = SaveUpdateToDB();
   }

   if (!defined($commit_log_id)) {
      print "no commit id returned.  we'll just exit now shall we?\n";
      exit 2;
   }
}

sub handle_updater_end {
    if (defined($Updates{committerAll})) {
       $Updates{committerAll} .= ", " . $Updates{committer};   
    } else {
       $Updates{committerAll} = $Updates{committer};   
    }
    print "found Committer= [$Updates{committerAll}]\n";
}

sub handle_messageto_end
{
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

	my $commit_log = FreshPorts::Commit_Log->new($dbh);

	print "load_xml_into_db.pl::SaveUpdateToDB --- start\n";

	my $message_id      = $dbh->quote($Updates{MessageId});

	my $existing_commit_id = GetExistingMessageID($message_id, $dbh);

	if (defined($existing_commit_id)) {
		FreshPorts::Utilities::ReportError('warning', "message $message_id has already been added to the database", 0);

		if ($overwrite) {
			FreshPorts::Utilities::ReportError('warning', "message $message_id being removed", 0);

			# delete that message
			$sql = "delete from commit_log where message_id = $message_id";
			$sth = $dbh->prepare($sql);
			if (!$sth->execute) {
				FreshPorts::Utilities::ReportError('warning', "Could not execute SQL $sql $dbh->err", 1);
			}
		} else {
			my $nullvalue;
			return $nullvalue;
		}
	}

	$message_date       = $dbh->quote(
							sprintf "%04u/%02u/%02u %02u:%02u:%02u %s", 
							$Updates{messageyear}, $Updates{messagemonth},  $Updates{messageday}, 
							$Updates{messagehour}, $Updates{messageminute}, $Updates{messagesecond}, 
							$Updates{messagezone});

	my $message_subject = $dbh->quote($Updates{MessageSubject});

	my $date_added      = "now()";
	if (defined($Updates{DateAdded})) {
		$date_added = $Updates{DateAdded};
	}

	my $commit_date     = $dbh->quote(
							sprintf "%04u/%02u/%02u %02u:%02u:%02u %s", 
							$Updates{dateyear}, $Updates{datemonth}, $Updates{dateday}, 
							$Updates{timehour}, $Updates{timeminute}, $Updates{timesecond}, 
							$Updates{timezone});

	my $committer       = $dbh->quote($Updates{committer});
	my $description     = $dbh->quote($Updates{log});
   
	$commit_log->{message_id}		= $message_id;
	$commit_log->{message_date}		= $message_date;
	$commit_log->{message_subject}	= $message_subject;
	$commit_log->{date_added}		= $date_added;
	$commit_log->{commit_date}		= $commit_date;
	$commit_log->{committer}		= $committer;
	$commit_log->{description}		= $description;
	$commit_log->{system_id}		= $SystemID;

	$id = $commit_log->save();

	print "load_xml_into_db.pl::SaveUpdateToDB --- finish\n";

	return $id;
}

sub GetExistingMessageID($;$) {
	my $message_id = shift;
	my $dbh        = shift;
	my $sth;
	my $sql;
	my @row;
   
	$sql = "select id from commit_log where message_id = $message_id";

	print "GetExistingMessageID => sql='$sql'\n";
   
	$sth = $dbh->prepare($sql);
	if (!$sth->execute) {
		FreshPorts::Utilities::ReportError('warning', "Could not execute SQL $sql", 1);
	}

	@row = $sth->fetchrow_array();
   
	$sth->finish();
   
	return $row[0];
}

sub Pathname_ID($;$) {
	# obtain the element id from the full path-file name
	my $filename = shift;
	my $dbh      = shift;

	my $sql;
	my $sth;
	my @row;

	my $quoted_filename = $dbh->quote($filename);
	$sql = "select Pathname_ID($quoted_filename)";

	print "sql = '$sql'\n";

	$sth = $dbh->prepare($sql);
	if (!$sth->execute) {
		FreshPorts::Utilities::ReportError('warning', "Could not execute SQL $sql", 1);
	}

	@row = $sth->fetchrow_array();

	$sth->finish();

	return $row[0];
}

sub SystemBranchIDGetOrCreate($;$;$) {   
	# obtain the system_branch_id for the given version of this system
	my $system_id	= shift;
	my $branch_name	= shift;
	my $dbh			= shift;

	my $sql;
	my $sth;
	my @row;

	my $SystemBranchID;

	$sql = "select SystemBranchIDGet($system_id, " . $dbh->quote($branch_name) . ")";

	print "sql = '$sql'\n";

	$sth = $dbh->prepare($sql);
	if (!$sth->execute) {
		FreshPorts::Utilities::ReportError('warning', "Could not execute SQL $sql", 1);
	}

	@row = $sth->fetchrow_array();

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
	}

	$sth->finish();

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

	return $row[0];
}

sub SystemBranchElementInsert($;$;$;$) {
	my $SystemBranchID	= shift;
	my $ElementID		= shift;
	my $RevisionName	= shift;
	my $dbh				= shift;

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
}

sub Element_Add($;$;$) {
   my $element_name = shift;
   my $FileDirFlag  = shift;
   my $dbh          = shift;
   
   my $element_id;
   my $sth;
   my $sql;
   my @row;

   $sql = "select Element_Add('$element_name', '$FileDirFlag')";

   print "sql is $sql\n";

   if (!$debug) {
      $sth = $dbh->prepare($sql);
      $sth->execute ||
              FreshPorts::Utilities::ReportError('warning', "Could not execute SQL $sql ... maybe invalid?", 1);

      @row = $sth->fetchrow_array();
   
      $sth->finish();
   }

   $element_id = $row[0];

   return $element_id;
}
