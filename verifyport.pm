#!/usr/bin/perl -w
#
# $Id: verifyport.pm,v 1.42.2.12 2003-05-16 01:14:08 dan Exp $
#
# Copyright (c) 2001-2003 DVL Software
#

package FreshPorts::VerifyPort;

use strict;
use element;
use category;
use port;
use commit_log_ports;
use commit_log_port_elements;
use utilities;
use committer_opt_in;

require File::Basename;
require Sys::Syslog;

#
# WARNING: this hash is filled up during the processing of a single
# message.  You must call InitialiseNewMessage() at the start of each
# new message.

sub InitialiseNewMessage() {
	# now empty function
	# kept in case needed in future
}

sub _CompileListOfPorts($;$;$) {
	my $commit_log_id	= shift;
	my $Files			= shift;
	my $dbh				= shift;

	my %ListOfPorts;			# returned from this function
	my %CategoriesChecked;	# contains category class objects.

	my $value;
	my $category;
	my $port;

	print "STARTING _CompileListOfPorts ................................\n";

	foreach $value (@{$Files}) {
		my ($action, $filename, $revision, $commit_log_element_id) = @$value;

		my ($subtree, $category_name, $port_name, $extra) = split/\//,$filename, 4;
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
			print "yes, this file is in the ports tree\n";

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
					if (!$port) {
						print "* * * we'll have to load/create that port!\n";
						$port = FreshPorts::Port->new($dbh);

						# this is all that's needed to retrieve a port which exists
						$port->{partialpathname} = "$category_name/$port_name";


						$port->FetchByPartialPathName();
						#
						# the above fetch may have failed.
						# in which case, $port->{id} will not be defined
						# we will take advantage of that later.
						# for now, all we want is a complete list of ports.
						#
						if (!defined($port->{id})) {
							#
							# these are the values needed to create a new port
							#
							$port->{category_id}	= $category->{id};
							$port->{name}			= $port_name;
							$port->{category}		= $category_name;
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
					if ($extra eq $FreshPorts::Constants::FILE_MAKEFILE && $action eq $FreshPorts::Constants::REMOVE ) {
						#
						# we are deleted (local value, never actually saved to db)
						#
						$port->{deleted} = 1;
						print "THIS PORT HAS BEEN DELETED\n";
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


sub SaveChangesToPortsTree($;$;$) {
	my $commit_log_id	= shift;
	my $Files			= shift;
	my $dbh				= shift;

	my %ListOfPorts;
	my %CommitLogPorts;	# hash of commit_log_ports objects

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
	%ListOfPorts = _CompileListOfPorts($commit_log_id, $Files, $dbh);

	#
	# only do this stuff if we actually have any ports to update...
	#
	if (scalar %ListOfPorts) {
		#
		# for each port, ensure that we save away the new needs_refresh value
		# This will also create any ports which need to be created
		#
		while (my ($portname, $port) = each %ListOfPorts) {
			print "port = $portname, port_id = '";
			if (defined($port->{id})) {
				print $port->{id};
			}

			print "', category_id='";
			if (defined($port->{category_id})) {
				print $port->{category_id};
			}

			my $needs_refresh = $port->GetNeedsRefreshForNewPort();
			print "', needs_refresh='$needs_refresh'\n";

			$port->{last_commit_id} = $commit_log_id;

			$port->save();

			#
			# make sure we record what ports were updated by this commit
			#
			# we create a new one each time because of the update method...
			# it checks for {saved}... not very OO, but oh...
			#
			$commit_log_ports = FreshPorts::CommitLogPorts->new($dbh);

			$commit_log_ports->{commit_log_id}	= $commit_log_id;
			$commit_log_ports->{port_id}			= $port->{id};
			$commit_log_ports->{needs_refresh}	= $needs_refresh;

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
			$commit_log_ports->{port}	= $port;
			$CommitLogPorts{$portname}	= $commit_log_ports;

			print "size of %CommitLogPorts = '" . scalar(keys %CommitLogPorts) . "' $portname\n";
		}

		_RecordPortFilesTouchedByThatCommit($commit_log_id, $Files, \%ListOfPorts, $dbh);

		_DeleteDeletedPorts      (\%ListOfPorts, $dbh);
		_UndeleteResurrectedPorts(\%ListOfPorts, $Files, $dbh);
	}

	return %CommitLogPorts;
}

sub FetchAllFiles($;$) {
	#
	# fetch all the files associated with this commit
	#

	my $Files		= shift;
	my $dbh			= shift;

	
	my $action;
	my $filename;
	my $revision;
	my $commit_log_element_id;
	my $value;

	my $basename;
	my $MakefileCount = 0;

	print "fetching all files from this commit.\n";

	foreach $value (@{$Files}) {
		($action, $filename, $revision, $commit_log_element_id) = @$value;

		#
		# there is no sense in fetching removed files
		#
		my $directory = File::Basename::dirname ($filename);
		my $FILE      = File::Basename::basename($filename);

		my $DESTDIR   = "$FreshPorts::Config::path_to_tree/$directory";
		my $SRCDIR    = $directory;
		my $REVISION  = $revision;
	
		if ($action ne $FreshPorts::Constants::REMOVE) {

			#
			# fetch this file into the ports tree
			#

			print "fetching \$DESTDIR = [$DESTDIR], \$SRCDIR = [$SRCDIR], \$FILE = [$FILE] \$REVISION = [$REVISION]\n";

			if (!FreshPorts::Utilities::FetchFile($DESTDIR, $SRCDIR, $FILE, $REVISION)) {
				FreshPorts::Utilities::ReportError('warning', "Sorry, but we couldn't fetch all the files as required when we encounter a SLAVE/MASTER port", 0);
			}
		} else {
			print "files was removed.  not fetching $SRCDIR/$FILE/?revision=$REVISION\n";
		}
	}

	return 1;
}
	

sub _RecordPortFilesTouchedByThatCommit($;$;$;$) {
	#
	# This function will populate the commit_log_ports table.
	#
	my $commit_log_id	= shift;
	my $Files			= shift;
	my $PortsRef		= shift;
	my $dbh				= shift;

	my %Ports 			= %{$PortsRef};

	my $portname;						# of the form "$category/$port"
	my $port;							# of type FreshPorts::Element
	my $commit_log_port_elements;	# of type FreshPorts::CommitLogPortElements

	my $action;
	my $filename;
	my $revision;
	my $commit_log_element_id;
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
		($action, $filename, $revision, $commit_log_element_id) = @$value;

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
				$commit_log_port_elements->{commit_log_id}			= $commit_log_id;
				$commit_log_port_elements->{port_id}					= $port->{id};
				$commit_log_port_elements->{commit_log_element_id}	= $commit_log_element_id;
				$commit_log_port_elements->save();
			} else {
				print "... but is on the list of IgnoredItems!\n\n";
			}
		}
	}
}

sub RefreshAllPortsTouchedByCommit($;$;$) {
	#
	# given the ports touched by this commit
	# refresh each of them
	#

	my $CommitLogPortsRef		= shift;
	my %CommitLogPorts			= %{$CommitLogPortsRef};
	my $fetch_before_refresh	= shift;
	my $dbh							= shift;

	my $port;
	my $error 		= 0;
	my $ErrorFound = 0;

	#
	# refresh each and every port we are told about
	#
	print "# # # # Refreshing ports # # # #\n\n";
	while (my ($portname, $commit_log_ports) = each %CommitLogPorts) {
		$port = $commit_log_ports->{port};
		print "port = $portname, port_id = '$port->{id}', category_id='$port->{category_id}', needs_refresh='$commit_log_ports->{needs_refresh}'\n";

		$error = $port->RefreshFromFiles($commit_log_ports->{needs_refresh}, $fetch_before_refresh);
		if (!$error) {
			
			# after refreshing from the files, save the results
			$port->save();
			

			# and then update the commit_log_ports

			$commit_log_ports->{needs_refresh}	= 0;
			$commit_log_ports->{port_version}	= $port->{version};
			$commit_log_ports->{port_revision}	= $port->{revision};

			$commit_log_ports->save();

			#
			# commit everything we've done.  we don't want it falling over during
			# the daily summary creation and then doing a rollback.
			#
			$dbh->commit();
		} else {
			$dbh->rollback();
			$ErrorFound = 1;
		}
	}

	print "# # # # done refreshing ports # # # #\n\n";
	return $ErrorFound;
}

sub _DeleteDeletedPorts($;$) {
	#
	# For each deleted port, delete the element which corresponds to that port
	#

	my $PortsRef	= shift;
	my %Ports		= %{$PortsRef};
	my $dbh			= shift;

	my $element		= FreshPorts::Element->new($dbh);

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

	my $PortsRef	= shift;
	my %Ports		= %{$PortsRef};
	my $Files		= shift;
	my $dbh			= shift;

	my $element		= FreshPorts::Element->new($dbh);

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
				my ($action, $filename, $revision, $commit_log_element_id) = @$value;
		
				my ($subtree, $category_name, $port_name, $extra) = split/\//,$filename, 4;
				if (!defined($extra)) {
					$extra = '';
				}
				print "  inspecting: '$action', '$filename', '$revision', '$subtree', '$category_name', '$extra'\n";

				if ($category_name eq $port->{category} && $port->{name} eq $port_name) {
					print "  ...found a file from that port\n";
					if ($action eq $FreshPorts::Constants::ADD || $action eq $FreshPorts::Constants::MODIFY) {
						print "  ...hmmm, we are modifying a file for a port which is deleted...";
						print "  ........ I will resurrect that port for you\n";
						FreshPorts::Utilities::ReportError('notice', "Port $category_name/$port_name needs to be Resurrected", 0);
						$element->{id}     = $port->{element_id};
						$element->{status} = $FreshPorts::Element::Active;
						$element->update_status();
						print "  ........ done!\n";
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
