#
# $Id: verifyport.pm,v 1.56 2012-09-25 18:11:23 dan Exp $
#
# Copyright (c) 2001-2006 DVL Software
#

package FreshPorts::VerifyPort;

use strict;
use FreshPorts::branches;
use FreshPorts::element;
use FreshPorts::category;
use FreshPorts::port;
use FreshPorts::commit_log_ports;
use FreshPorts::commit_log_port_elements;
use FreshPorts::commit_log_ports_elements;
use FreshPorts::utilities;
use FreshPorts::committer_opt_in;
use FreshPorts::master_slave;
use FreshPorts::vuxml_mark_commits;

require File::Basename;
require Sys::Syslog;
use POSIX qw{strftime};

#
# WARNING: this hash is filled up during the processing of a single
# message.  You must call InitialiseNewMessage() at the start of each
# new message.

sub InitialiseNewMessage() {
	# now empty function
	# kept in case needed in future
}

sub _CompileListOfPorts($;$;$;$;$) {
	my $CommitBranch  = shift; # which branch is this on? head? RELENG_9_1_0
	my $commit_log_id = shift;
	my $Files         = shift;
	my $dbh           = shift;
	my $RepoType      = shift;

	my %ListOfPorts;	# returned from this function
	my %CategoriesChecked;	# contains category class objects.

	my $value;
	my $category;
	my $port;

	print "STARTING _CompileListOfPorts ................................\n";
	print "for a commit on 'branch': '$CommitBranch'\n";

	foreach $value (@{$Files}) {
		my ($action, $filename, $revision, $commit_log_element_id, $element_id) = @$value;
		
		# filename might look like one of these two:
		#
		# /ports/head/ftp/vsftpd/Makefile
		# /ports/branches/RELENG_9_1_0/games/spellathon/Makefile
		#
		# You need to split them differently
		
		# define them first
		my ($emptyLeadingSlash, $subtree, $branches, $branch, $category_name, $port_name, $extra);
		
		# depending on which branch we are one, we need to split this path differently
		if ($CommitBranch eq $FreshPorts::Constants::HEAD)
		{
		  print "this commit is on head\n";
		  ($emptyLeadingSlash, $subtree,            $branch, $category_name, $port_name, $extra) = split/\//,$filename, 6;
		}
		else
		{
		  print "this commit is NOT ON head\n";
		  ($emptyLeadingSlash, $subtree, $branches, $branch, $category_name, $port_name, $extra) = split/\//,$filename, 7;
		}
		# FILE ==: Modify, /ports/head/ftp/vsftpd/Makefile, 303756, , head, ftp, vsftpd/Makefile, 1935356
		# for README, GUIs, UIDs: category_name will be empty.
		print "FILE ==: $action, $filename, $revision, $subtree, $category_name, ";
		if (defined($port_name)) {
			print "$port_name, ";
		}

		if (defined($extra)) {
			print "$extra, ";
		}

		print "$commit_log_element_id\n";

		# is this file is in the ports tree?
		# e.g. ports/LEGAL won't get through here because $port_name will not be defined.
		if ($subtree eq $FreshPorts::Config::ports_prefix && defined($category_name) && defined($port_name)) {
			print "YES, this file is in the ports tree\n";

			if (!defined($FreshPorts::Constants::IgnoredItems{$category_name}) && !defined($FreshPorts::Constants::IgnoredItems{$port_name})) {
				# find the port for this filename....
				if ($ListOfPorts{"$category_name/$port_name"}) {
					print "but we have already seen the port $category_name/$port_name\n\n";
					# we've already added this port to the list of ports for this commit
				} else {
					#
					# check that the category exists.  and the port.
					# But we don't create any ports yet.
					# we do that, if necessary, later.
					#

					print "checking for category='$category_name'\n";

					$category = $CategoriesChecked{$category_name};
					if (!defined($category)) {
						$category = FreshPorts::Category->new($dbh);
						$category->{name} = $category_name;
						my $category_id = $category->FetchByName();

						if (defined($category_id)) {
							print "Category $category_name has ID = $category_id\n";
						} else {
							# we need to create this catgory.
							# remember to grab ports/<category>/pkg/COMMENT
							# actually, it's in ports/<category>/Makefile as a COMMENT
							print "creating new category $category_name\n";
							FreshPorts::Utilities::ReportError('warning', "creating new category $category_name", 0);

							$category->{is_primary} = 1;
							$category_id = $category->save();
							if (!defined($category_id)) {
								FreshPorts::Utilities::ReportError('warning', "failed to create new category $category_name", 1);
							}

						$CategoriesChecked{$category_name} = $category;
						}
					} else {
						print "found that category $category_name in the cache\n";
					}

					print "checking for port='$category_name/$port_name'\n";

					$port = $ListOfPorts{"$category_name/$port_name"};
					
					# we won't create a new port based on "cat/port", because that could be a file in the category's directory.
					# instead, we want to ensure that "cat/port" refers to a directory, versus a file.
					# such a situation exists if $extra has some value.
					# see 201205251025.q4PAPOvV092118@repoman.freebsd.org where 'deskutils/svn.log' was accidently added
					# in a previous commit, and then removed.  The previous code would add svn.log as a port, and then
					# add it as an element and a port.  See _RecordPortsAndElements() where svn.log would be listed in 
					# both CommitLogPorts and Files.
					#

					if (defined($extra)) {
						if (!$port) {
							print "* * * not found in existing cache.  we'll have to load/create that port!\n";
							$port = FreshPorts::Port->new($dbh, $RepoType);

							# this is all that's needed to retrieve a port which exists
							if ($CommitBranch eq $FreshPorts::Constants::HEAD)
							{
							  $port->{partialpathname} = "/$subtree/$branch/$category_name/$port_name";
							}
							else
							{
							  $port->{partialpathname} = "/$subtree/branches/$branch/$category_name/$port_name";
							}

							$port->FetchByPartialPathName();
							#
							# the above fetch may have failed.
							# in which case, $port->{id} will not be defined
							# we will take advantage of that later.
							# for now, all we want is a complete list of ports.
							#
							if (!defined($port->{id})) {
								print "port not retrieved with $port->{partialpathname}.  This must be a new port.\n";
								#
								# these are the values needed to create a new port
								#
								$port->{category_id} = $category->{id};
								$port->{name}        = $port_name;
								$port->{category}    = $category_name;

								#
								# we are creating a new port (probably), so we make it active.
								# we need this set for later use.
								#
								$port->SetActive();
							}

							print "SETTING CATEGORY = $port->{category_id}\n";
							$ListOfPorts{"$category_name/$port_name"} = $port;
						} else {
							print "found that port $category_name/$port_name in the cache\n";
						}

						#
						# $port now contains the port for this file.
						# let's adjust the needs_refresh value.
						#
						#
						# if we just deleted the Makefile for this port, there's no sense in refreshing the port.
						# because it's been deleted.
						#
						if ($extra eq $FreshPorts::Constants::FILE_MAKEFILE && ($action eq $FreshPorts::Constants::REMOVE || $action eq $FreshPorts::Constants::DELETE)) {
							#
							# EDIT 2020-07-30 - for git processing, we want to delete the parent of $extra when we detect that the
							# port Makefile is being deleted. see https://news.freshports.org/2020/07/29/git-changing-libraries-gave-us-new-xml-options/
							# This should be straight forward.
							#
							# we are deleted (local value, never actually saved to db)
							#
							$port->{deleted} = 1;
							print "THIS PORT HAS BEEN DELETED\n";
						}
					}
					else
					{
					  print "\$extra is not defined, therefore, this is not considered a port.\n";
					}
				}
			} else {
				print "... but is on the list of IgnoredItems!\n\n";
			}
		} else {
			print "that file isn't in the ports tree\n";
		}
	}	

	print "ENDING _CompileListOfPorts ................................\n";

	return %ListOfPorts;
}


sub SaveChangesToPortsTree($;$;$;$;$) {
	my $CommitBranch  = shift;  # e.g. head or RELENG_9_1_0 or RELENG_10
	my $commit_log_id = shift;
	my $Files         = shift;
	my $dbh           = shift;
	my $RepoType      = shift;

	my %ListOfPorts;
	my %CommitLogPorts;	# hash of commit_log_ports objects

	my $CreatingNewPort;

	#
	# we record the ports affected by a given commit
	#
	my $commit_log_ports;


	#
	# %Files will contain a hash of all the files associated with this commit
	# We will do three things
	#   1 - populate PortsChecked with a list of ports 
	#   2 - ensure said ports and their categories exit
	#   3 - set needs_refresh for each port according to the files touched
	#       by this commit
	#	


	#
	# This list of ports may not all be in the database.
	# We'll deal with that as we go along.
	#
	%ListOfPorts = _CompileListOfPorts($CommitBranch, $commit_log_id, $Files, $dbh, $RepoType);
	
	print "into SaveChangesToPortsTree()\n";

	#
	# only do this stuff if we actually have any ports to update...
	#
	if (scalar %ListOfPorts) {
		#
		# for each port, ensure that we save away the new needs_refresh value
		# This will also create any ports which need to be created
		#
		while (my ($portname, $port) = each %ListOfPorts) {
			print "port = $portname";
			if (defined($port->{id})) {
				print ", port_id = '". $port->{id} . "'";
			}
			print "\n";
			
			if ($FreshPorts::Config::Debug_FetchBeforeSavingPort && defined($port->{id})) {
				print "Fetching port before saving\n";
				print "/usr/bin/fetch $FreshPorts::Config::FreshPortsURL$portname"
			}

			print "category_id='";
			if (defined($port->{category_id})) {
				print $port->{category_id};
			}

			my $needs_refresh = $port->GetNeedsRefreshForNewPort();
			print "', needs_refresh='$needs_refresh'\n";

			$port->{last_commit_id} = $commit_log_id;

			$CreatingNewPort = !defined($port->{id});

			$port->savePortTableOnly($CommitBranch);

			#
			# when creating a new port, we need to get the element_pathname
			# value, which is used later in the loading process
			#
			if ($CreatingNewPort) {
				print "just created that port.  Now loading it back in....\n";
				$port->FetchByID();
			}

			#
			# make sure we record what ports were updated by this commit
			#
			# we create a new one each time because of the update method...
			# it checks for {saved}... not very OO, but oh...
			#
			$commit_log_ports = FreshPorts::CommitLogPorts->new($dbh);

			$commit_log_ports->{commit_log_id} = $commit_log_id;
			$commit_log_ports->{port_id}       = $port->{id};
			$commit_log_ports->{needs_refresh} = $needs_refresh;

			if ($commit_log_ports->{needs_refresh} == -1) {
				FreshPorts::Utilities::ReportError('warning', "Cannot GetNeedsRefreshForNewPort.  Fetch failed", 1);
			}

			$commit_log_ports->save();

			#
			# now we save the commit_log_port with the port
			# so we can process them for refresh later...
			# and then zero out needs_refresh.
			# messy.  Perhaps there is a neater way.
			#
			$commit_log_ports->{port}  = $port;
			$CommitLogPorts{$portname} = $commit_log_ports;

			print "size of %CommitLogPorts for " . $portname . " is '" . scalar(keys %CommitLogPorts) . "'\n";
		}

		_RecordPortFilesTouchedByThatCommit($commit_log_id, $Files, \%ListOfPorts, $dbh);

		_DeleteDeletedPorts      (\%ListOfPorts, $dbh);
		_UndeleteResurrectedPorts(\%ListOfPorts, $Files, $dbh);
	}

	#
	# The commit_log_ports_elements table records the ports and elements (which
	# are not part of a port) which were touched by a commit.
	#
	_RecordPortsAndElements($commit_log_id, $Files, \%CommitLogPorts, $dbh);

	return %CommitLogPorts;
}

sub ScrollToThatCommit($;$;$;$) {
	#
	# At one time, we fetched individual files.
	# Then we did: svn co -r N
	# Now it's: git checkout N
	#

	my $repo     = shift;
	my $branch   = shift;
	my $git_hash = shift;
	my $dbh      = shift;

	my $FetchOK = 1;

	print "into ScrollToThatCommit with: branch = '$branch' looking for commit = '$git_hash'";
	print "do a git checkout of that hash.\n";

	# if we have a hash
	if (defined($git_hash) && $git_hash ne '')
	{
		my $startTime = time;
		# this is a path to the repo directory, we still need the repo name
		my $RepoName = FreshPorts::Branches::GetRepoNameForBranch($repo, $branch);
		$FetchOK = FreshPorts::Utilities::gitCheckout("$FreshPorts::Config::RepoDir/$RepoName", $git_hash);

		my $elapsedTime = time - $startTime;

		print "Elapsed time for gitCheckout" . strftime("\%H:\%M:\%S", gmtime($elapsedTime)) . "\n";

		return $FetchOK;
	}

	return $FetchOK;
}

sub FetchAllFiles($;$;$;$;$;$) {
	#
	# fetch all the files associated with this commit
	# Actually, it's only files within the ports tree.
	#

	my $Repository   = shift;
	my $CommitBranch = shift;
	my $Files        = shift;
	my $svn_revision = shift;
	my $dbh          = shift;
	my $RepoType     = shift;

	
	my $action;
	my $filename;
	my $revision;
	my $commit_log_element_id;
	my $element_id;
	my $value;

	my $basename;
	my $MakefileCount = 0;
	
	my $FetchOK = 1;

	print "fetching all files from this commit.\n";
	print "Repository='$Repository'\n";
	print "CommitBranch='$CommitBranch'\n";
	print "svn_revision='$svn_revision'\n";
	
	# this is where we fetch the files to disk
	# we are dealing only with svn here.
	# we have only one repo. 

        # this is where we fetch the files to disk
        my $REPODIR = FreshPorts::Branches::GetPathToRepoForBranchSVN($CommitBranch);

	# if we have a revision	
	if (defined($svn_revision) && $svn_revision ne '')
	{
		my $startTime = time;
		$FetchOK = FreshPorts::Utilities::svnUpFile($REPODIR, '', $svn_revision);
		
		my $elapsedTime = time - $startTime;
		
		print "Elapsed time for svn up " . strftime("\%H:\%M:\%S", gmtime($elapsedTime)) . "\n";

		return $FetchOK;
	}

	LOOP:
	foreach $value (@{$Files}) {
		($action, $filename, $revision, $commit_log_element_id, $element_id) = @$value;
		
		print "looking at files: ($action, $filename, $revision, $commit_log_element_id, $element_id)\n";

		#
		# fetch only files in the ports tree
		#
		if (!($filename =~ m|^/?ports/|)) {
			print "outside ports tree: ignoring $filename\n";
			next;
		}

		#
		# do not fetch directories
		# THIS MAKES USE OF THE FACT that SVN puts added directories into
		# the commit message with a trailing /
		# if that process discontinues, we'll have to find another way to do this.
		#
		if ($filename =~ m|^.*/$|) {
#			print "this is a directory.  Will not fetch $filename\n";
#			next;
		}
		
		# there, the filename will be of the form: ports/www/libmicrohttpd/distinfo
		# we need to convert this to www/libmicrohttpd/distinfo
		# we use ports/www/libmicrohttpd/distinfo in the database
		# but the repo uses www/libmicrohttpd/distinfo and so does our ports tree on disk
		#
		#

		# XXX - this needs to cater for branches.
		# this is the step which removes the prefix from the directory
		$filename =~ s|$FreshPorts::Config::ports_prefix/||g;
		
		
		if ($filename =~ m|^.*/$|) {
			# this 'file' is actually a directory
			# thus, complete directory by appending file
			print "this is a directory.  Will fetch $filename\n";
		}
		

		# now we set up the repository location for this file..
		my $SVNITEM  = $filename;
		my $REVISION = $revision;
	
		#
		# there is no sense in fetching removed files
		#
		if ($action ne $FreshPorts::Constants::REMOVE && $action eq $FreshPorts::Constants::DELETE) {

			#
			# fetch this file into the ports tree
			#

			print "fetching \$REPODIR = [$REPODIR], \$SVNITEM = [$SVNITEM (was $filename)] \$REVISION = [$REVISION]\n";

			$FetchOK = FreshPorts::Utilities::svnUpFile($REPODIR, $SVNITEM, $REVISION);
			if (!$FetchOK) {
				FreshPorts::Utilities::ReportError('warning', "Sorry, but we couldn't fetch all the files", 0);
				last LOOP;
			}
		} else {
			print "file was removed.  not fetching $SVNITEM revision=$REVISION\n";
		}
	}

	return $FetchOK;
}
	

sub _RecordPortFilesTouchedByThatCommit($;$;$;$) {
	#
	# This function will populate the commit_log_port_element table.
	#
	my $commit_log_id = shift;
	my $Files         = shift;
	my $PortsRef      = shift;
	my $dbh           = shift;

	my %Ports         = %{$PortsRef};

	my $portname;                 # of the form "$category/$port"
	my $port;                     # of type FreshPorts::Element
	my $commit_log_port_elements; # of type FreshPorts::CommitLogPortElements

	my $action;
	my $filename;
	my $revision;
	my $commit_log_element_id;
	my $element_id;
	my $value;

	my $subtree;
	my $category_name;
	my $port_name;
	my $extra;

	$commit_log_port_elements = FreshPorts::CommitLogPortElements->new($dbh);

	print "\n\nThat message is all done under Commit ID = '$commit_log_id'\n";

	print "the size of \@Files is ", scalar(@{$Files}), "\n";

	#
	# in this loop assign a value to needs_refresh for each port
	#
	foreach $value (@{$Files}) {
		($action, $filename, $revision, $commit_log_element_id, $element_id) = @$value;

		($subtree, $category_name, $port_name, $extra) = split/\//,$filename, 4;
		print "FILE ==: $action, $filename, $revision, $subtree, $category_name, ";
		if (defined($port_name)) {
			print "$port_name, ";
		}

		if (defined($extra)) {
			print "$extra, ";
		}

		print "$commit_log_element_id\n";

		# is this file is in the ports tree?
		# e.g. ports/LEGAL won't get through here because $port_name will not be defined.
		if (defined($extra))
		{
			if ($subtree eq $FreshPorts::Config::ports_prefix && defined($category_name) && defined($port_name)) {
				print "yes, this file is in the ports tree\n";

				if (!defined($FreshPorts::Constants::IgnoredItems{$category_name}) && !defined($FreshPorts::Constants::IgnoredItems{$port_name})) {
					# find the port for this filename....
					$port = $Ports{"$category_name/$port_name"};
					if (!$port) {
						FreshPorts::Utilities::ReportError('warning', "could not find port '$category_name/$port_name' in hash.", 1);
					}

					#
					# record which files go with what port...
					#
					$commit_log_port_elements->{commit_log_id}         = $commit_log_id;
					$commit_log_port_elements->{port_id}               = $port->{id};
					$commit_log_port_elements->{commit_log_element_id} = $commit_log_element_id;
					$commit_log_port_elements->save();
				} else {
					print "... but is on the list of IgnoredItems!\n\n";
				}
			}
		}
		else
		{
			print "ignoring that item because it is not part of a port\n";
		}
	}
}

sub _RecordPortsAndElements($;$;$;$) {
	#
	# This function will populate the commit_log_ports_elements table.
	#
	my $commit_log_id     = shift;
	my $Files             = shift;
	my $CommitLogPortsRef = shift;
	my $dbh               = shift;

	my %CommitLogPorts    = %{$CommitLogPortsRef};

	my %CommitLogPortElements = (); # list of all elements touched by this commit; used to avoid duplicates.

	my $portname;                  # of the form "$category/$port"
	my $port;                      # of type FreshPorts::Element
	my $commit_log_ports_elements; # of type FreshPorts::CommitLogPortsExtra
	my $commit_log_ports;

	my $action;
	my $filename;
	my $revision;
	my $commit_log_element_id;
	my $element_id;
	my $value;

	$commit_log_ports_elements = FreshPorts::CommitLogPortsElements->new($dbh);

	print "into _RecordPortsAndElements\n";
	print "\n\nThat message is all done under Commit ID = '$commit_log_id'\n";

	print "the size of \@Files is ", scalar(@{$Files}), "\n";

	my $ExtraElement;
	#
	# for each file, see if it's under an existing port
	#
	foreach $value (@{$Files}) {
		$ExtraElement = 1;
		($action, $filename, $revision, $commit_log_element_id, $element_id) = @$value;
		print "checking file '$filename' : element_id = '$element_id'\n";

		# We do this assignment here because a reset didn't work
		%CommitLogPorts = %{$CommitLogPortsRef};
		while (my ($portname, $commit_log_ports) = each %CommitLogPorts) {
			$port = $commit_log_ports->{port};
			

			print " checking port " . $port->{'element_pathname'} . "\n";
			if ($filename =~ m|^/?\Q$port->{element_pathname}\E/|) {
				print " YES!  that was a match!\n";
				$ExtraElement = 0;
				last;
			} else {
#				print " OK, we'll try the next port\n";
			}
		}
		
		if ($ExtraElement) {
			print "That file is outside any port\n";

			if ($CommitLogPortElements{$commit_log_id . '||' . $element_id}) {
				print "That element_id ($element_id) has already been recorded against this commit\n";
			} else {
				$CommitLogPortElements{$commit_log_id . '||' . $element_id} = 1;
				#
				# record which files go with what port...
				#
				$commit_log_ports_elements->{commit_log_id} = $commit_log_id;
				$commit_log_ports_elements->{element_id}    = $element_id;
				$commit_log_ports_elements->save();
			}
		}
	}

	# we have recorded all non-ports.  Now we record the ports
	# We do this assignment here because a reset didn't work
	print "saving to commit_log_ports_elements\n";

	%CommitLogPorts = %{$CommitLogPortsRef};
	while (my ($portname, $commit_log_ports) = each %CommitLogPorts) {
		$port = $commit_log_ports->{port};
	    print $port->{category} . '/' . $port->{name} . "\n";
		if ($CommitLogPortElements{$commit_log_id . '||' . $port->{element_id}}) {
			print "That element_id ($element_id) has already been recorded against this commit\n";
		} else {
			$CommitLogPortElements{$commit_log_id . '||' . $port->{element_id}} = 1;
			$commit_log_ports_elements->{commit_log_id} = $commit_log_id;
			$commit_log_ports_elements->{element_id}    = $port->{element_id};
			$commit_log_ports_elements->save();
		}
	}
	
	print "done _RecordPortsAndElements\n";
}

sub RefreshAllPortsTouchedByCommit($;$;$;$;$;$) {
	#
	# given the ports touched by this commit
	# refresh each of them
	#

	my $Repository           = shift;
	my $CommitBranch         = shift;
	my $CommitLogPortsRef    = shift;
	my %CommitLogPorts       = %{$CommitLogPortsRef};
	my $fetch_before_refresh = shift;
	my $svn_revision         = shift;
	my $dbh                  = shift;

	my $port;
	my $error;
	my $ErrorFound = 0;

	#
	# refresh each and every port we are told about
	#
	print "# # # # Refreshing ports # # # #\n\n";
	while (my ($portname, $commit_log_ports) = each %CommitLogPorts) {
		$port = $commit_log_ports->{port};
		print "port = $portname, port_id = '$port->{id}', category_id='$port->{category_id}', needs_refresh='$commit_log_ports->{needs_refresh}'\n";

		#
		# Sometimes a port can be deleted in one commit, and a later
		# commit will remove a missed file.  If this port is deleted, don't refresh it.
		# If we don't need to refresh it, we don't need to save it.
		#
		if ($port->IsActive()) {
			$error = $port->RefreshFromFiles($Repository, $CommitBranch, $commit_log_ports->{needs_refresh}, $fetch_before_refresh, $svn_revision);
		} else {
			print "This port is deleted: not refreshing.\n";
			$error = 0;
		}

		if (!$error) {
			if ($port->IsActive()) {
				# after [perhaps] refreshing from the files, save the results
				$port->save($CommitBranch);  # perhaps we need two types of saves.  One after refresh, one not after refresh.
			} else {
				print "This port is deleted: not saving.\n";
			}

			print "Updating commit_log_ports\n";

			# and then update the commit_log_ports

			$commit_log_ports->{needs_refresh} = 0;
			$commit_log_ports->{port_version}  = $port->{version};
			$commit_log_ports->{port_revision} = $port->{revision};
			$commit_log_ports->{port_epoch}    = $port->{portepoch};

			$commit_log_ports->save();
		} else {
			$ErrorFound = 1;
		}
	}

	print "# # # # done refreshing ports # # # #\n\n";
	return $ErrorFound;
}

sub RefreshAllSlavePortsOfPortsTouchedByCommit($;$;$;$;$;$;$) {
	#
	# given the ports touched by this commit,
	# refresh any slaves
	#
	my $Repository           = shift;
	my $CommitBranch         = shift; # something like head or branches/2020Q3
	my $CommitLogPortsRef    = shift;
	my %CommitLogPorts       = %{$CommitLogPortsRef};
	my $fetch_before_refresh = shift;
	my $dbh                  = shift;
	my $RepoType             = shift;


	# head or 2020Q3
	my $BranchStripped = FreshPorts::Branches::stripBranchesToGetBranchName($CommitBranch);

	my $ErrorFound = 0;
	my $MasterSlave;
	my %Slaves;
	my %tmp;

	print "# # # # Start refreshing slave ports # # # #\n\n";

	# For each port in this commit

	$MasterSlave = FreshPorts::MasterSlave->new($dbh, $RepoType);

	while (my ($portname, $commit_log_ports) = each %CommitLogPorts) {
		my $port = $commit_log_ports->{port};

		#    find all it's slave ports  ... we do this on head, by design.
		#    because head will be correct, the branch may not have all the slave ports, but head will.
		%tmp = $MasterSlave->FetchByMaster("$port->{category}/$port->{name}");

		#    add each one to a hash
		while (my ($PortName, $ignore) = each %tmp) {
			$Slaves{$PortName} = 1;
		}
	}

	# For each slave port
	while (my ($PortName, $ignore) = each %Slaves) {
		# fetch it
		my $port = FreshPorts::Port->new($dbh, $RepoType);
		
		my $pathname;

		# we have to fetch from the branch
		$port->{partialpathname} = $FreshPorts::Config::Ports_Default_Directory . '/' . $PortName;
		if ($BranchStripped eq $FreshPorts::Constants::HEAD)
		{
		  $pathname = $FreshPorts::Config::DB_Root_Prefix_PORTS . '/head/' . $PortName;
		}
		else
		{
		  $pathname = $FreshPorts::Config::DB_Root_Prefix_PORTS . '/branches/' . $BranchStripped . '/' . $PortName;
		}

        $port->{partialpathname} = $pathname;
		my $port_id = $port->FetchByPartialPathName();
		# if no such port, then it has not yet been committed to this branch
		if (!defined($port_id)) {
			print 'no such port on this branch: ' . $BranchStripped . ".\n";
			print "port not retrieved with $port->{partialpathname}.  This must be a new port.\n";

			#
			# these are the values needed to create a new port
			#
			my ($category_name, $port_name) = split/\//,$PortName, 2;
			$port->CreatePortOnBranch($category_name, $port_name, $BranchStripped);

			print "new port created with port id = " . $port->{id} . "\n";
			
			my $port_id = $port->FetchByPartialPathName();
		}

		#  refresh it
		#  XXX WE ARE REFRESHING WITHOUT FIRST DOING AN SVN UP
		$port->RefreshFromFiles($Repository, $BranchStripped, 1, 0, ''); # refresh the port, don't fetch the files

		#  save it
		$port->save($BranchStripped);

		print "refreshed " . $port->{category} . '/' . $port->{name} . "\n";

		undef $port;
	}

	print "# # # # Finish refreshing slave ports # # # #\n\n";

	return $ErrorFound;
}

sub MarkVulnerableCommits($;$;$) {
	#
	# given the ports touched by this commit
	# mark any commits that are vulnerable
	#


	my $CommitLogPortsRef    = shift;
	my %CommitLogPorts       = %{$CommitLogPortsRef};
	my $fetch_before_refresh = shift;
	my $dbh                  = shift;

	my $port;
	my $error;
	my $ErrorFound = 0;

	my $MarkCommits = FreshPorts::vuxml_mark_commits->new(DBHandle => $dbh);

	#
	# mark each and every port we are told about, if vulnerable
	#
	print "# # # # Marking vulnerable # # # #\n\n";
	while (my ($portname, $commit_log_ports) = each %CommitLogPorts) {
		$port = $commit_log_ports->{port};
		print "port = $portname, port_id = '$port->{id}', category_id='$port->{category_id}', needs_refresh='$commit_log_ports->{needs_refresh}'\n";

		print "Updating commit_log_ports\n";

		# and then update the commit_log_ports
		$MarkCommits->RecordVulnerabilitiesForThisPortVersion(
			$commit_log_ports->{commit_log_id},
			$port->{id},
			$port->{package_name},
			$port->{version},
			$port->{revision},
			$port->{portepoch});
	}

	print "# # # # done marking vulnerable commits # # # #\n\n";

	return $ErrorFound;
}

sub _DeleteDeletedPorts($;$) {
	#
	# For each deleted port, delete the element which corresponds to that port
	#

	my $PortsRef = shift;
	my %Ports    = %{$PortsRef};
	my $dbh      = shift;

	my $element  = FreshPorts::Element->new($dbh);

	#
	# refresh each and every port we are told about
	#
	print "# # # # Deleting deleted ports # # # #\n\n";
	while (my ($portname, $port) = each %Ports) {
		if (defined($port->{deleted})) {
			print "deleting : port = $portname, port_id = '$port->{id}', ' element_id = $port->{element_id}'\n";

			$element->{id} = $port->{element_id};
			if (defined($element->FetchByID())) {
				$element->{status} = $FreshPorts::Element::Deleted;
				$element->save();
			}
		}
	}
	print "# # # # Finished deleting deleted ports # # # #\n\n";
}

sub _UndeleteResurrectedPorts($;$;$) {
	#
	# For each port, see if it's deleted. If it is, then that was the
	# state before we processed this commit.  For such ports, look for 
	# a modify or add to a Makefile where
	# the port is actually deleted.  Then set that port to undeleted
	# and save.  Actually, it's port.element_id which needs to be reset
	# in this case, but you get the point....
	#

	my $PortsRef = shift;
	my %Ports    = %{$PortsRef};
	my $Files    = shift;
	my $dbh      = shift;

	my $element  = FreshPorts::Element->new($dbh);

	my $value;

	#
	# refresh each and every port we are told about
	#
	print "# # # # Resurrecting deleted ports # # # #\n\n";
	while (my ($portname, $port) = each %Ports) {
		if ($port->{status} eq $FreshPorts::Element::Deleted) {
			print "found a deleted port: port='$port->{name}', port_id='$port->{id}', element_id='$port->{element_id}'\n";
			print "now looking for files which were modified...\n";

			foreach $value (@{$Files}) {
				my ($action, $filename, $revision, $commit_log_element_id, $element_id) = @$value;

				#
				# these look like: /ports/head/lang/yap/Makefile
				#        might be: /ports/branches/2020Q4/emulators/citra/Makefile
				#
				
				my $filename_stripped = $element->strip_ports_dir($filename);
				my ($category_name, $port_name, $extra) = split/\//,$filename_stripped, 3;
				if (!defined($extra)) {
					$extra = '';
				}
				print "  inspecting: '$action', '$filename', '$filename_stripped', '$revision', '$category_name', '$port_name', '$extra'\n";

				if ($category_name eq $port->{category} && $port->{name} eq $port_name) {
					print "  ...found a file from that port\n";
					if ($action eq $FreshPorts::Constants::ADD || $action eq $FreshPorts::Constants::MODIFY) {
						print "  ...hmmm, we are modifying a file for a port which is deleted...";
						print "  ........ I will resurrect that port for you\n";
						FreshPorts::Utilities::ReportError('notice', "Port $category_name/$port_name needs to be Resurrected", 0);
						$element->{id}     = $port->{element_id};
						$element->{status} = $FreshPorts::Element::Active;
						$element->update_status();
						print "  ........ resurrection done!\n";
						print "  we will not examine any more files for this port!\n";
						# we are looping through files for a single port, only resurrect once.
						last;
					}
				}
			}
			print "  finished looking through the files\n";
		}
	}
	print "# # # # Finished resurrecting deleted ports # # # #\n\n";
}

FreshPorts::Utilities::InitSyslog();

1;
