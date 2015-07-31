#!/usr/bin/perl
#
# $Id: port.pm,v 1.73 2013-04-24 12:22:43 dan Exp $
#
#
# Copyright (c) 2001-2005 DVL Software
#

package FreshPorts::Port;
require Exporter;
require config;
require element;
require utilities;
require committer_opt_in;
require port_dependencies;
require branches;

use strict;
use config;
use constants;

# for Ade's special code in update_depends_helper
use List::MoreUtils qw(uniq);

# for testing results from file existance
use Scalar::Util qw(looks_like_number);

# for testing dates, as recommended by "B. Estrade" <estrabd@gmail.com>
use POSIX qw/strftime/;

sub freshports_ConvertPortPathToStandardLocation($;$) {
	my $CommitBranch = shift;
	my $pathname     = shift;

	# look for $FreshPorts::Config::path_to_tree and 
	# replace it with /usr.  Why? so we refer to the 
	# real ports tree and not the one we are using
	
	my $PathToRepo = FreshPorts::Branches::GetPathToRepoForBranch($CommitBranch);

	print "freshports_ConvertPortPathToStandardLocation() is converting '$pathname' ";
	$pathname =~ s/$PathToRepo/$FreshPorts::Constants::UsualPortsTreeLocation/g;
	print " to '$pathname'\n";

	return $pathname;
}

# =================================

sub _initialize {
	my $this = shift;

	$this->{portname}			= '';
	$this->{name}				= '';
	$this->{short_description}	= '';
	$this->{long_description}	= '';
	$this->{version}			= '';
	$this->{revision}			= '';
	$this->{maintainer}			= '';
	$this->{homepage}			= '';
	$this->{master_sites}		= '';
	$this->{extract_suffix}		= '';
	$this->{package_exists}		= '';
	$this->{depends_build}		= '';
	$this->{depends_run}		= '';
	$this->{depends_lib}		= '';
	$this->{forbidden}			= '';
	$this->{broken}				= '';
	$this->{deprecated}			= '';
	$this->{ignore}				= '';
	$this->{master_port}		= '';
	$this->{latest_link}		= '';
	$this->{no_latest_link}		= '';
	$this->{no_package}			= '';
	$this->{package_name}		= '';
	$this->{portepoch}			= '';
	$this->{restricted}			= '';
	$this->{no_cdrom}			= '';
	$this->{expiration_date}	= '';
	$this->{is_interactive}		= '';
	$this->{only_for_archs}		= '';
	$this->{not_for_archs}		= '';
	$this->{status}				= '';
	$this->{showconfig}			= '';
	$this->{license}			= '';
	$this->{fetch_depends}		= '';
	$this->{extract_depends}	= '';
	$this->{patch_depends}		= '';
	$this->{uses}			    = '';

	$this->{categories}			= '';
	$this->{element_pathname}   = '';
}

sub _GetValuesFromRow {
	my $this = shift;
	my $row  = shift;

	$this->{id} 				= $row->{id};
	$this->{element_id}			= $row->{element_id};
	$this->{category_id}		= $row->{category_id};
	$this->{category}			= $row->{category};
	$this->{name}				= $row->{name};

	$this->{short_description}	= $row->{short_description};
	$this->{long_description}	= $row->{long_description};
	$this->{version}			= $row->{version};
	$this->{revision}			= $row->{revision};
	$this->{maintainer}			= $row->{maintainer};
	$this->{homepage}			= $row->{homepage};
	$this->{master_sites}		= $row->{master_sites};
	$this->{extract_suffix}		= $row->{extract_suffix};
	$this->{package_exists}		= $row->{package_exists};
	$this->{depends_build}		= $row->{depends_build};
	$this->{depends_run}		= $row->{depends_run};
	$this->{depends_lib}		= $row->{depends_lib};
	$this->{forbidden}			= $row->{forbidden};
	$this->{broken}				= $row->{broken};
	$this->{deprecated}			= $row->{deprecated};
	$this->{ignore}				= $row->{ignore};
	$this->{master_port}		= $row->{master_port};
	$this->{latest_link}		= $row->{latest_link};
	$this->{no_latest_link}		= $row->{no_latest_link};
	$this->{no_package}			= $row->{no_package};
	$this->{package_name}		= $row->{package_name};
	$this->{portepoch}			= $row->{portepoch};
	$this->{restricted}			= $row->{restricted};
	$this->{no_cdrom}			= $row->{no_cdrom};
	$this->{expiration_date}	= $row->{expiration_date};
	$this->{is_interactive}		= $row->{is_interactive};
	
	$this->{only_for_archs}		= $row->{only_for_archs};
	$this->{not_for_archs}		= $row->{not_for_archs};
	$this->{status}				= $row->{status};
	$this->{showconfig}			= $row->{showconfig};
	$this->{license}			= $row->{license};
	$this->{fetch_depends}		= $row->{fetch_depends};
	$this->{extract_depends}	= $row->{extract_depends};
	$this->{patch_depends}		= $row->{patch_depends};
	$this->{uses}			    = $row->{uses};

	$this->{categories}			= $row->{categories};
	$this->{last_commit_id}		= $row->{last_commit_id};
	$this->{element_pathname}   = $row->{element_pathname};
}

# =================================

sub new {
	my $this		= {};
	my $class		= shift;

	$this->{dbh}	= shift;

	bless $this;

	$this->_initialize();

	return $this;
}

# this is the type of save we usually do
sub save {
    my $this = shift;

    my $CommitBranch = shift;
    
    $this->_save($CommitBranch, 1);
}


#
# here, we are updating only the last_commit_id or creating a brand new port
# the usual practice involves refreshing the port from files and then doing
# a save()
# Otherwise, we'll find up saving and processing the dependencies, which can contain 'old' values.
# e.g. gmake:/usr/ports/devel/gmake might be in the field but your current PORTSDIR is /usr/local/PORT-head
# this will cause a dependency look up to fail
#

sub savePortTableOnly {
    my $this = shift;

    my $CommitBranch = shift;
    
    $this->_save($CommitBranch, 0);
}


sub _save {
	my $this = shift;

	my $CommitBranch = shift;
	my $FullSave     = shift;

	print "into FreshPorts::Port::save\n";

	#
	# to save, element_id and category_id must be valid
	#

	my $dbh = $this->{dbh}; # just a short cut...
	my $sth;
	my $sql;
	my @row;
	my $expiration_date_alt;
	my $is_interactive_alt;
	my $not_for_archs_alt;
	my $only_for_archs_alt;
	my $restricted_alt;
	my $no_cdrom_alt;
	my $license_alt;

	if ($this->{id}) {
		# we are updating
		

		# NOTE: NULLIfEmpty invokes dbh->quote()
		# these items were escaped here because I thought it was a problem not assigning them to a variable.
		$is_interactive_alt  = FreshPorts::Utilities::NULLIfEmpty($dbh, $this->{is_interactive});
		$expiration_date_alt = FreshPorts::Utilities::NULLIfEmpty($dbh, $this->{expiration_date});
		$not_for_archs_alt   = FreshPorts::Utilities::NULLIfEmpty($dbh, $this->{not_for_archs});
		$only_for_archs_alt  = FreshPorts::Utilities::NULLIfEmpty($dbh, $this->{only_for_archs});
		$restricted_alt      = FreshPorts::Utilities::NULLIfEmpty($dbh, $this->{restricted});
		$no_cdrom_alt        = FreshPorts::Utilities::NULLIfEmpty($dbh, $this->{no_cdrom});
		$license_alt         = FreshPorts::Utilities::NULLIfEmpty($dbh, $this->{license});

		$sql = "
update ports  
   set short_description = " . $dbh->quote($this->{short_description})                                   . ",
       long_description  = " . $dbh->quote($this->{long_description})                                    . ", 
       version           = " . $dbh->quote($this->{version})                                             . ", 
       revision          = " . $dbh->quote($this->{revision})                                            . ", 
       maintainer        = " . $dbh->quote($this->{maintainer})                                          . ", 
       homepage          = " . FreshPorts::Utilities::NULLIfEmpty($dbh, $this->{homepage})               . ", 
       master_sites      = " . FreshPorts::Utilities::NULLIfEmpty($dbh, $this->{master_sites})           . ", 
       extract_suffix    = " . $dbh->quote($this->{package_exists})                                      . ", 
       depends_build     = " . FreshPorts::Utilities::NULLIfEmpty($dbh, $this->{depends_build})          . ", 
       depends_run       = " . FreshPorts::Utilities::NULLIfEmpty($dbh, $this->{depends_run})            . ", 
       depends_lib       = " . FreshPorts::Utilities::NULLIfEmpty($dbh, $this->{depends_lib})            . ", 
       forbidden         = " . FreshPorts::Utilities::NULLIfEmpty($dbh, $this->{forbidden})              . ", 
       broken            = " . FreshPorts::Utilities::NULLIfEmpty($dbh, $this->{broken})                 . ", 
       deprecated        = " . FreshPorts::Utilities::NULLIfEmpty($dbh, $this->{deprecated})             . ", 
       ignore            = " . FreshPorts::Utilities::NULLIfEmpty($dbh, $this->{ignore})                 . ", 
       master_port       = " . FreshPorts::Utilities::NULLIfEmpty($dbh, $this->{master_port})            . ",
       latest_link       = " . FreshPorts::Utilities::NULLIfEmpty($dbh, $this->{latest_link})            . ", 
       no_latest_link    = " . FreshPorts::Utilities::NULLIfEmpty($dbh, $this->{no_latest_link})         . ", 
       no_package        = " . FreshPorts::Utilities::NULLIfEmpty($dbh, $this->{no_package})             . ", 
       package_name      = " . FreshPorts::Utilities::NULLIfEmpty($dbh, $this->{package_name})           . ", 
       portepoch         = " . FreshPorts::Utilities::NULLIfEmpty($dbh, $this->{portepoch})              . ", 
       restricted        = " . $restricted_alt                                                           . ", 
       no_cdrom          = " . $no_cdrom_alt                                                             . ",  
       expiration_date   = " . $expiration_date_alt                                                      . ", 
       is_interactive    = " . $is_interactive_alt                                                       . ", 
       only_for_archs    = " . $only_for_archs_alt                                                       . ",
       not_for_archs     = " . $not_for_archs_alt                                                        . ",
       showconfig        = " . FreshPorts::Utilities::NULLIfEmpty($dbh, $this->{showconfig})             . ",
       license           = " . $license_alt                                                              . ",
       fetch_depends     = " . FreshPorts::Utilities::NULLIfEmpty($dbh, $this->{fetch_depends})          . ", 
       extract_depends   = " . FreshPorts::Utilities::NULLIfEmpty($dbh, $this->{extract_depends})        . ", 
       patch_depends     = " . FreshPorts::Utilities::NULLIfEmpty($dbh, $this->{patch_depends})          . ", 
       uses              = " . FreshPorts::Utilities::NULLIfEmpty($dbh, $this->{uses})                   . ", 
       categories        = " . FreshPorts::Utilities::NULLIfEmpty($dbh, $this->{categories});


		# we don't always have this value, so we don't change it....
		if (defined($this->{last_commit_id})) {
			$sql .= "\n, last_commit_id		= $this->{last_commit_id}";
		}
		
		$sql .= " where id = $this->{id}";

		print "sql = $sql\n";

		$sth = $this->{dbh}->prepare($sql);
		$sth->execute ||
			FreshPorts::Utilities::ReportError('warning', "Could not execute SQL $sql ... maybe invalid? " . $dbh->errstr, 1);
	} else {
		# we are inserting
		# do we really need to quote these things?

		if (!$this->{category_id} && $this->{partialpathname}) {
			#
			# we have a partial name but no element.
			# let's get the element
			#
			$this->{element_id} = $this->_FetchElementIDByPartialPathName();
		}

		if (!$this->{element_id}) {
			FreshPorts::Utilities::ReportError('warning', "Cannot create new port.  Insufficient data: no element id", 1);
		}

		if (!$this->{category_id}) {
			FreshPorts::Utilities::ReportError('warning', "Cannot create new port.  Insufficient data: no category id", 1);
		}

		#
		# update this sql to insert all fields?

		$this->{id} = FreshPorts::Database::GetNextValue($FreshPorts::Constants::ports_seq, $dbh);

		$sql = "insert into ports (id, element_id, category_id";

        # really, this should always be supplied, but we are retrofiting this, so be cautious		
		if (defined($this->{last_commit_id})) {
		    $sql .= ', last_commit_id';
		}

        $sql .= ") values ( \
				$this->{id}, \
				$this->{element_id}, \ 
				$this->{category_id}";
				
		if (defined($this->{last_commit_id})) {
			$sql .= ', ' . $this->{last_commit_id};
		}

        $sql .= ")";

		print "sql is $sql\n";

		$sth = $this->{dbh}->prepare($sql);
		if (!$sth->execute) {
			FreshPorts::Utilities::ReportError('warning', "Could not execute SQL $sql ... maybe invalid? " . $dbh->errstr, 1);
		}
		
	}

    if ($FullSave) {
        $this->update_depends($CommitBranch);
    }

	# after savings, return the ID
	return $this->{id};
}

sub FetchByID {
	my $this	= shift;

	my $dbh;
	my $sql;
	my $sth;
	my $row;

	$dbh = $this->{dbh};

	$sql = "
   select ports.*,
          categories.name as category, 
          element.name    as name, 
          element_pathname(element.id, FALSE) as element_pathname
     from ports, categories, element 
    where ports.id          = $this->{id} 
      and ports.category_id = categories.id 
      and ports.element_id  = element.id";
 
#	print "sql = '$sql'\n";

	$sth = $dbh->prepare($sql);
	if (!$sth->execute) {
		FreshPorts::Utilities::ReportError('warning', "Could not execute SQL $sql", 1);
	}

	$row = $sth->fetchrow_hashref();

	$sth->finish();

	# no sense setting values if we didn't get anything...
	if ($row) {
		$this->_GetValuesFromRow($row);
	}

	return $this->{id};
}

sub FetchByPartialPathName {
	# obtain the port based on the pathname supplied
	my $this = shift;

	my $dbh;
	my $sql;
	my $sth;
	my $row;
	my $tmp;

	$dbh = $this->{dbh};
	if (!$dbh) {
		FreshPorts::Utilities::ReportError('warning', " no database handle!", 1);
	}

 	my $element;

	$this->{element_id} = $this->_FetchElementIDByPartialPathName();
	#
	# if there is no element corresponding to this port anme, we can't find anything...
	#
	if (!$this->{element_id}) {
		return $this->{element_id};
	}

	$tmp = $dbh->quote($this->{name});

	$sql = "
   select ports.*,
          categories.name as category,
          element.name    as name,
          element_pathname(element.id, FALSE) as element_pathname
     from ports, categories, element
    where ports.element_id  = $this->{element_id}
      and ports.category_id = categories.id
      and ports.element_id  = element.id";

	print "sql = '$sql'\n";

	$sth = $dbh->prepare($sql);
	if (!$sth->execute) {
		FreshPorts::Utilities::ReportError('warning', "Could not execute SQL $sql", 1);
	}

	$row = $sth->fetchrow_hashref();

	$sth->finish();

	# no sense setting values if we didn't get anything...
	if ($row) {
		$this->_GetValuesFromRow($row);
	}

	return $this->{id};
}

sub _FetchElementIDByPartialPathName {
	# obtain the element based on the pathname supplied
	my $this = shift;

	my $dbh;

	$dbh = $this->{dbh};
	if (!$dbh) {
		FreshPorts::Utilities::ReportError('warning', "no database handle!", 1);
	}

 	my $element;

	$element = FreshPorts::Element->new($dbh);
	
	print "fetching by _FetchElementIDByPartialPathName: '" . $this->{partialpathname} ."'\n";;
	$element->{pathname} = $this->{partialpathname};
	$this->{element_id} = $element->FetchByName();

	return $this->{element_id};
}



sub _ExtractValuesFromMakefile {
	#
	# returns 0 for success, -1 for failure
	#

	my $this         = shift;
	my $CommitBranch = shift;

	my $result;
	my $makecommand;
	my $ErrorMessage = '';	# stores the result of the latest make command
	                        # in case we need it for error reporting
	my $OtherErrors  = '';	# gets the results of the TmpFile used to collect errors.

	my $SVNDIR        = FreshPorts::Branches::GetPathToRepoForBranch      ($CommitBranch);
	my $SVNDIR_CHROOT = FreshPorts::Branches::GetPathToRepoForBranchCHROOT($CommitBranch);
	my $MakefileDirectory = "$SVNDIR/$this->{category}/$this->{name}";

	my $Makefile = "$MakefileDirectory/$FreshPorts::Constants::FILE_MAKEFILE";

	if (-f $Makefile) {
		# good, the Makefile actually exists.  This should be the case.  If not, something
		# rather unusual is happening.
	} else {
		# If the Makefile does not exist, suspect a repocopy.
		# A repocopy is the process of manually moving things around within the cvs repository.
		# This preserves commit history when a port is being renamed, but it makes life difficultJailShowConfigScript
		# for FreshPorts, which only tracks commits.
		FreshPorts::CommitterOptIn::RecordErrorDetails("$this->{category}/$this->{name}", "I did not find a Makefile for this port, and none was mentioned in the commit.  If a repocopy has been done, please ignore this message.");
	}

	my $TmpFile = FreshPorts::Utilities::TmpFileName("$this->{category}.$this->{name}.make-error");

	# we create this directory because it helps us to locate problems
	#
	# create this directory to catch errors
	# such as the pre-everything having only one ':'
	#
	if ($FreshPorts::Config::mkdir_pkg) {
		mkdir "pkg",0;
	}


	#
	#
	# IF YOU CHANGE THE MAKE COMMAND, CHANGE THE SPLIT!!!!!!!!!!!!!!!
	#
	#
	$makecommand = "/usr/local/bin/sudo /usr/sbin/chroot -u $FreshPorts::Config::JailUser $FreshPorts::Config::JailBaseDir $FreshPorts::Config::JailPortScript $SVNDIR_CHROOT $this->{category}/$this->{name} 2>$TmpFile";

	print "makecommand = $makecommand\n";

	my $MakeResults = `$makecommand`;
	# save this for later reference
	$result = $?;

	print 'Result = ' . $result . "\n";

	#
	# if we get an error such as this: "/usr/home/dan/ports/french/homard/Makefile", line 56: Need an operator
	# (caused by spaces instead of tabs in a section such as do-install:), then $MakeResults will be empty
	# and the errors will be captured in the tmp file we created.
	#
	if ($result != 0) {
		#
		# Some errors aren't caught by the Makefile script, but are grabbed in the tmp file
		# Such as:
		# -s: not found
		# "/usr/home/dan/ports/french/homard/Makefile", line 39: warning: " -s"
		# returned non-zero status
		# caused by doing:     unames!= ${UNAME} -s
		# without first doing: .include  <bsd.port.pre.mk>
		#

		print 'size is ' . -s $TmpFile;
		print "\n";

		if (-s $TmpFile > 0) {
			print "getting error message from temp file\n";
			$ErrorMessage = "Error message is: " . `cat $TmpFile`;
		}

		if ($MakeResults ne '') {
			# save the results for error reporting
			$ErrorMessage .= "Make results are : " . $MakeResults;
		}

		$ErrorMessage = "This command (FreshPorts code 1):\n\n$makecommand\n\nproduced this error:\n\n$ErrorMessage";
		FreshPorts::CommitterOptIn::RecordErrorDetails("$this->{category}/$this->{name}", $ErrorMessage);
		$result = -1;
	}

	# remove that error collection file
	unlink($TmpFile);

	my $mastersites = '';
	if ($result == 0) {
        	my $TmpFile = FreshPorts::Utilities::TmpFileName("$this->{category}.$this->{name}.make-mastersites-error");
          	print "trying to get master sites.  Errors will be in '$TmpFile'\n";
                my $mastersitescommand = "/usr/local/bin/sudo /usr/sbin/chroot -u $FreshPorts::Config::JailUser $FreshPorts::Config::JailBaseDir $FreshPorts::Config::JailMasterSitesScript $SVNDIR_CHROOT $this->{category}/$this->{name} 2>$TmpFile";

		print "'$mastersitescommand'\n";
		$mastersites = `$mastersitescommand`;
		# save this for later reference
		$result = $?;

		chomp($mastersites);	# remove that trailing whitespace.

		# we'll need this for error reporting
		if ($result != 0) {
			print 'size is ' . -s $TmpFile;
			print "\n";

			if (-s $TmpFile > 0) {
				print "getting error message from temp file\n";
				$ErrorMessage = "Error message is: " . `cat $TmpFile`;
			}

			if ($mastersites ne '') {
				# save the results for error reporting
				$ErrorMessage .= "Make results are : " . $mastersites;
			}

			$ErrorMessage = "This command (FreshPorts code 2):\n\n$mastersitescommand\n\nproduced this error:\n\n$ErrorMessage";
			# save the results for error reporting
			FreshPorts::CommitterOptIn::RecordErrorDetails("$this->{category}/$this->{name}", $ErrorMessage);
		}

		# remove that error collection file
		unlink($TmpFile);

	}

	my $showconfig = '';
	if ($result == 0) {
		my $TmpFile = FreshPorts::Utilities::TmpFileName("$this->{category}.$this->{name}.showconfig");
		print "trying to get showconfig.  Errors will be in '$TmpFile'\n";
                my $showconfigcommand = "/usr/local/bin/sudo /usr/sbin/chroot -u $FreshPorts::Config::JailUser $FreshPorts::Config::JailBaseDir $FreshPorts::Config::JailShowConfigScript $SVNDIR_CHROOT $this->{category}/$this->{name} 2>$TmpFile";

		print "'$showconfigcommand'\n";
		$showconfig = `$showconfigcommand`;
		# save this for later reference
		$result = $?;

		chomp($showconfig);	# remove that trailing whitespace.

		# we'll need this for error reporting
		if ($result != 0) {
			print 'size is ' . -s $TmpFile;
			print "\n";

			if (-s $TmpFile > 0) {
				print "getting error message from temp file\n";
				$ErrorMessage = "Error message is: " . `cat $TmpFile`;
			}

			if ($showconfig ne '') {
				# save the results for error reporting
				$ErrorMessage .= "Make results are : " . $showconfig;
			}

			$ErrorMessage = "This command (FreshPorts code 2):\n\n$showconfigcommand\n\nproduced this error:\n\n$ErrorMessage";
			# save the results for error reporting
			FreshPorts::CommitterOptIn::RecordErrorDetails("$this->{category}/$this->{name}", $ErrorMessage);
		}

		# remove that error collection file
		unlink($TmpFile);

	}

	print "\$result='$result'\n";
	print "\$showconfig='$showconfig'\n";

	# remove previously created directory
	if ($FreshPorts::Config::mkdir_pkg) {
		rmdir "pkg";
	}

	#
	# we need to check this return value.  if it fails, we need to know
	#

	if ($result == 0) {

		(my $portname,       my $packagename,    my $descrpath,        my $categories,
		 my $portversion,    my $portrevision,   my $shortdescription, my $CommentFile,
		 my $maintainer,     my $extractsuffix,  my $builddepends,     my $rundepends,
		 my $libdepends,     my $forbidden,      my $broken,           my $deprecated,
		 my $ignore,         my $master_port,    my $latest_link,      my $no_latest_link,
		 my $no_package,     my $pkgnameprefix,  my $pkgnamesuffix,    my $portepoch,
		 my $restricted,     my $no_cdrom,       my $expiration_date,  my $is_interactive,
		 my $only_for_archs, my $not_for_archs,  my $license,          my $fetchdepends, 
		 my $extractdepends, my $patchdepends,   my $uses) = split(/\n/s, $MakeResults);

		my $package_name = $pkgnameprefix . $portname . $pkgnamesuffix;

		# some ports contains :patch in their depends information.  
		# 		
		# freshports.org=# select name, category from ports_active where depends_run like '%:patch%' or depends_build like '%:patch%' or depends_lib like '%:patch%';
		#        name        |   category
		# -------------------+--------------
		#  py-omniorb        | devel
		#  ruby-gdbm         | databases
		#  ruby-iconv        | converters
		#  ruby-rd-mode.el   | textproc
		#  ruby-sdl          | devel
		#  ruby-tk           | x11-toolkits
		#  omniNotify        | devel
		#  pg_filedump       | databases
		#  boinc-astropulse  | astro
		#  cduce             | lang
		#  gauche-gdbm       | databases
		#  kon2              | chinese
		#  p5-B-Hooks-Parser | devel
		# (13 rows)
		# 
		# freshports.org=#

		$builddepends   = $this->depends_stripper(freshports_ConvertPortPathToStandardLocation($CommitBranch, FreshPorts::Utilities::trim_multiple_to_single(FreshPorts::Utilities::trim($builddepends))));
		$rundepends     = $this->depends_stripper(freshports_ConvertPortPathToStandardLocation($CommitBranch, FreshPorts::Utilities::trim_multiple_to_single(FreshPorts::Utilities::trim($rundepends))));
		$libdepends     = $this->depends_stripper(freshports_ConvertPortPathToStandardLocation($CommitBranch, FreshPorts::Utilities::trim_multiple_to_single(FreshPorts::Utilities::trim($libdepends))));
		$fetchdepends   = $this->depends_stripper(freshports_ConvertPortPathToStandardLocation($CommitBranch, FreshPorts::Utilities::trim_multiple_to_single(FreshPorts::Utilities::trim($fetchdepends))));
		$extractdepends = $this->depends_stripper(freshports_ConvertPortPathToStandardLocation($CommitBranch, FreshPorts::Utilities::trim_multiple_to_single(FreshPorts::Utilities::trim($extractdepends))));
		$patchdepends   = $this->depends_stripper(freshports_ConvertPortPathToStandardLocation($CommitBranch, FreshPorts::Utilities::trim_multiple_to_single(FreshPorts::Utilities::trim($patchdepends))));

		$master_port =~ s|$SVNDIR_CHROOT/||;

		print " portname       = '$this->{name}'\n";
		print " packagename    = '$portname'\n";
		print " category       = '$this->{category}'\n";
		print " packagename    = '$packagename'\n";
		print " descrpath      = '$descrpath'\n";
		print " categories     = '$categories'\n";
		print " portversion    = '$portversion'\n";
		print " portrevision   = '$portrevision'\n";
		print " comment        = '$shortdescription'\n";
		print " CommentFile    = '$CommentFile'\n";
		print " maintainer     = '$maintainer'\n";
		print " extractsuffix  = '$extractsuffix'\n";
		print " mastersites    = '$mastersites'\n";
		print " builddepends   = '$builddepends'\n";
		print " rundepends     = '$rundepends'\n";
		print " libdepends     = '$libdepends'\n";
		print " fetchdepends   = '$fetchdepends'\n";
		print " extractdepends = '$extractdepends'\n";
		print " patchdepends   = '$patchdepends'\n";
		print " uses           = '$uses'\n";

		# eliminate multiple // : PR 174
		# to compensate for bug in File::PathConvert::realpath (which is no longer used; _GetRealPath)
		$descrpath =~ s|//|/|g;

		my $RealDescrPath = $this->_GetRealPath($descrpath);

		if (!defined($shortdescription)) {
                  die("OK, good, we have no short description");
		}

		# eliminate multiple // : PR 174
		# to compensate for bug in File::PathConvert::realpath (which is no longer used; _GetRealPath))
		$descrpath =~ s|//|/|g;

		# if it's defined, and it exists....
		my $longdescription = '';
		my $homepage        = '';
		if (looks_like_number($RealDescrPath))
		{
                  print "Description file does not exist: '$descrpath' (result of make -V DESCR)\n";
                  FreshPorts::CommitterOptIn::RecordErrorDetails("$this->{category}/$this->{name}", "Description file does not exist: '$descrpath' (result of make -V DESCR)\n");
	  	}
		else
		{
                   if (defined($RealDescrPath) && $RealDescrPath) {
                      print "invoking _GetDescrAndHomePage() with '$RealDescrPath'\n";
                      ($longdescription, $homepage) = $this->_GetDescrAndHomePage($RealDescrPath);
                   }
		}

		chomp($longdescription); # get rid of the trailing whitespace.

		print "12 \$shortdescription = '$shortdescription'\n";
		print "13 \$longdescription  = '$longdescription'\n";
		print "14 \$homepage='";
		if (defined($homepage)) {
			print "$homepage";
		}
		print "'\n";

		print "16 \$forbidden        = '$forbidden'\n";
		print "17 \$broken           = '$broken'\n";
		print "18 \$deprecated       = '$deprecated'\n";
		print "19 \$ignore           = '$ignore'\n";
		print "20 \$master_port      = '$master_port'\n";
		print "21 \$latest_link      = '$latest_link'\n";
		print "22 \$no_latest_link   = '$no_latest_link'\n";
		print "23 \$no_package       = '$no_package'\n";
		print "24 \$package_name     = '$package_name'\n";
		print "25 \$portepoch        = '$portepoch'\n";
		print "26 \$restricted       = '$restricted'\n";
		print "27 \$no_cdrom         = '$no_cdrom'\n";
		print "28 \$expiration_date  = '$expiration_date'\n";
		print "29 \$is_interactive   = '$is_interactive'\n";
		print "30 \$only_for_archs   = '$only_for_archs'\n";
		print "31 \$not_for_archs    = '$not_for_archs'\n";
		print "32 \$categories       = '$categories'\n";
		print "33 \$showconfig       = '$showconfig'\n";
		print "34 \$license          = '$license'\n";

		print "\n ---------------------------------------- \n";

		# convert a few values to zero if not defined.
		if (!defined($forbidden)) {
			$forbidden = '';
		}

		if (!defined($broken)) {
			$broken = '';
		}

		if (!defined($deprecated)) {
			$deprecated = '';
		}

		if (!defined($ignore)) {
			$ignore = '';
		}

		# put everything into the hash...

		$this->{portname}			= $portname;
		$this->{short_description}	= $shortdescription;
		$this->{long_description}	= $longdescription;
		$this->{version}			= $portversion;
		$this->{revision}			= $portrevision;
		$this->{maintainer}			= $maintainer;
		$this->{homepage}			= $homepage;
		$this->{master_sites}		= $mastersites;
		$this->{extract_suffix}		= $extractsuffix;
		$this->{depends_build}		= $builddepends;
		$this->{depends_run}		= $rundepends;
		$this->{depends_lib}		= $libdepends;
		$this->{forbidden}			= $forbidden;
		$this->{broken}				= $broken;
		$this->{deprecated}			= $deprecated;
		$this->{ignore}				= $ignore;
		$this->{master_port}		= $master_port;
		$this->{latest_link}		= $latest_link;
		$this->{no_latest_link}		= $no_latest_link;
		$this->{no_package}			= $no_package;
		$this->{package_name}		= $package_name;
		$this->{portepoch}			= $portepoch;
		$this->{restricted}			= $restricted;
		$this->{no_cdrom}			= $no_cdrom;
		$this->{expiration_date}	= $expiration_date;
		$this->{is_interactive}		= $is_interactive;
		$this->{only_for_archs}		= $only_for_archs;
		$this->{not_for_archs}		= $not_for_archs;
		$this->{showconfig} 		= $showconfig;
		$this->{license}            = $license;
		$this->{categories}			= $categories;
		$this->{fetch_depends}		= $fetchdepends;
		$this->{extract_depends}	= $extractdepends;
		$this->{patch_depends}		= $patchdepends;
		$this->{uses}	    		= $uses;
		# convert all whitespace to a single space
		# This arose from 200609130717.k8D7HpNc057638@repoman.freebsd.org
		#
		$this->{categories}			=~ s/\s+/ /g;

		$result = $this->_Validate();

	} else {
		print "That make failed:\n\n'$ErrorMessage'\n\n";
		FreshPorts::Utilities::ReportError('warning', "error executing make command for $this->{category}/$this->{name}: " . $ErrorMessage, 0);
	}

	return $result;
}

sub _Validate {
	#
	# run some sanity checks on the data input
	#
	my $this		= shift;
	my $result		= 0;
	my $ErrorMsg	= '';

	print "_Validating....\n";

	print "checking valid date: " . $this->{expiration_date} . "\n";
	# if field is non-empty, but not a valid date...
	if ($this->{expiration_date} && !IsValidDate($this->{expiration_date})) {
		$ErrorMsg .= " EXPIRATION_DATE contains '" . $this->{expiration_date} . "', which is not a valid date.";

		# allow the data to save...
	  $this->{expiration_date} = '';
	}

	# verify that CATEGORIES contains the primary category
	# make sure that $this->{categories} contains $this->{category}
	print "categories: " . $this->{categories} . "\n";
	my $category = "";
	
	my @categories = split(/ /, $this->{categories});
	
	my $primaryCategoryFound = 0;
	for (@categories) {
	   my ($category) = $_;
	      if ($this->{category} eq $category)
	      {
	        $primaryCategoryFound = 1;
            last;
	      }
	}
	
	if (!$primaryCategoryFound) {
	  $ErrorMsg = "\nThe CATEGORIES value ('" . $this->{categories} . "') does not contain the primary category ('" . $this->{category} . "')";
	}
	                 
	if ($ErrorMsg ne '') {
		FreshPorts::CommitterOptIn::RecordErrorDetails("$this->{category}/$this->{name}", $ErrorMsg);
		$result = -1;		
	}

	print "done _Validate\n";

	return $result;
}

# =================================
sub _GetDescrAndHomePage($) {
	my $this = shift;
	my $file = shift;
	my $url;
	my $DESCR;

	$DESCR = "";
	$url   = "";
	# this needs to open relative to the jail root.
	# to be pure, we shold do this as a script in the jail-root, but we'd have to call two scripts:
	# one for the homepage, one for te description.
	if (open (F, $FreshPorts::Config::JailBaseDir . $file))
	{
	
	  while(<F>){
		$DESCR .= $_;
		if(/WWW:(.*)/) {

#			print "found a home page of $url\n";

			$url = $1;
			$url =~  s/^\s+//g;
		}
	   }

	   close F;
	} else {
          print "Unable to open '$file' (result of make -V DESCR)\n";
          FreshPorts::CommitterOptIn::RecordErrorDetails("$this->{category}/$this->{name}", "Unable to open '$file' (result of make -V DESCR)\n");
	}
	
	my @result = ($DESCR, $url);

	return @result;
}


# =================================
sub _GetRealPath($) {
	my $this = shift;
  	my $file = shift;

	# invoke realpath on the supplied filename, from within our chroot
	my $makecommand = "/usr/local/bin/sudo /usr/sbin/chroot -u $FreshPorts::Config::JailUser $FreshPorts::Config::JailBaseDir $FreshPorts::Config::JailRealPath $file";

        print "about to invoke '$makecommand'\n";
        
	my $MakeResults = `$makecommand`;
        my $errorcode = $?;

	if ($errorcode != 0)
	{
          # some error, probably file does not exist
          $MakeResults = 0;
        }
        else
        {
          chomp($MakeResults);	# remove that trailing whitespace.
        }

        print "results are '$MakeResults'\n";

	print "errorcode='$errorcode'\n";

	return $MakeResults;
}



sub RefreshFromFiles($;$;$;$) {
#
# refresh this port based on the make files associated with it and the value of needs_refresh
# returns 0 for success, 1 for failure
#
	my $this		= shift;
        my $CommitBranch        = shift;
	my $needs_refresh	= shift;
	my $fetch_files		= shift;
	my $svn_revision	= shift;

	print "into RefreshFromFiles()\n";
	if (!defined($needs_refresh)) {
		FreshPorts::Utilities::ReportError('warning', "needs_refresh has no value", 1);
	}

	my $result = 0;
	my $error;

	my $FetchAttempts = $FreshPorts::Config::Fetch_Retry_Limit;

	#
	# fetch the files needed
	#
	if ($needs_refresh > 0 && $fetch_files) {
	  while ($FetchAttempts) {
	    if (defined($svn_revision) && $svn_revision ne '')
	    {
	      # svn up -r $svn_revision

              my $SVNDIR = FreshPorts::Branches::GetPathToRepoForBranch($CommitBranch);
              
              $result = FreshPorts::Utilities::svnUpFile($SVNDIR, '', $svn_revision);
              # match the results of _FetchFilesNeedingRefresh
              if ($result == 1) 
              {
                $result = 0;
              }
              else
              {
                $result = 1;
              }
            }
            else
            {
               die('I have no idea what I am doing here in RefreshFromFiles....');
            }
			if ($result == -1) {
				$FetchAttempts = 0;
				$error = 1;
			} else {
				if ($result == 0) {
					last;
				} else {
					print "fetch result = $result\n";
					# fetch failed
					# sleep, then try again
					Sys::Syslog::syslog('warning', "sleeping after fetch failed for ($this->{id}, $this->{category}, $this->{name}, $needs_refresh), result = $result");
					print "fetch failed, sleeping...\n";
					sleep $FreshPorts::Config::Fetch_Sleep_Time;
					$FetchAttempts--;
				}
			}
		}
	} else {
		print "this port does not need a refresh or we were told not to fetch\n";
	}

	# if we didn't use up all of our fetch attempts...
	if ($FetchAttempts) {
		$error = $this->_ExtractValuesFromMakefile($CommitBranch);
	}

	if (!$FetchAttempts || $error) {
		$result = 1;
	}

	return $result;
}

sub GetNeedsRefreshForNewPort {
	my $this = shift;

	# return -1 for fail
	#
	# When a new port is imported, we need to get the
	# makefile and determine whether or not this port
	# uses a description or comments file.  If it does,
	# then we adjust needs_refresh accordingly.
	# Note that some ports use another ports description
	# or comments file.  Therefore we may not have
	# to fetch those files in order to complete
	# the importing of a new port
	#

	#
	# Let's just use this for now.  See how it goes.
	#
	if (!defined($this->{deleted})) {
		return 7;
	} else {
		return 0
	}
}

sub IsActive {
	my $this = shift;

	return ($this->{status} eq $FreshPorts::Element::Active);
}

sub IsDeleted {
	my $this = shift;

	return ($this->{status} eq $FreshPorts::Element::Deleted);
}

sub SetActive {
	my $this = shift;

	my $OldStatus   = $this->{status};
	$this->{status} = $FreshPorts::Element::Active;

	return $OldStatus;
}


sub SetDeleted {
	my $this = shift;

	my $OldStatus   = $this->{status};
	$this->{status} = $FreshPorts::Element::Deleted;

	return $OldStatus;
}

sub IsValidDate($) {
  my $string = shift;

  # convert from YYYY-MM-DD format into variables
  my ($year, $mon, $mday) = split /-/, $string;

  # create a string
  my $test = strftime("%Y-%m-%d", 0, 0, 0, $mday, $mon - 1, $year - 1900);
  
  # do we have what we started with?
  return ($test eq $string) ? $string : undef;
}

sub update_depends {
  # for each of the depends in this port, update the ports_dependencies relationships
  my $this = shift;

  my $CommitBranch = shift;

  my $port_dependencies = FreshPorts::PortDependencies->new( $this->{dbh} );
  
  print 'about to delete port_dependencies for id ' . $this->{id} . "\n";
  $port_dependencies->{port_id} = $this->{id};
  $port_dependencies->delete();

  $this->update_depends_helper( $CommitBranch, $this->depends_stripper( $this->{depends_build}   ), 'B' ); # build
  $this->update_depends_helper( $CommitBranch, $this->depends_stripper( $this->{depends_run}     ), 'R' ); # runtime
  $this->update_depends_helper( $CommitBranch, $this->depends_stripper( $this->{depends_lib}     ), 'L' ); # library
  $this->update_depends_helper( $CommitBranch, $this->depends_stripper( $this->{fetch_depends}   ), 'F' ); # fetch
  $this->update_depends_helper( $CommitBranch, $this->depends_stripper( $this->{extract_depends} ), 'E' ); # extract
  $this->update_depends_helper( $CommitBranch, $this->depends_stripper( $this->{patch_depends}   ), 'P' ); # patch
}

sub depends_type_long {
  my $this = shift;
  my $depends_type = shift;  

  my %depends = (
    'B' => 'BUILD_DEPENDS',
    'R' => 'RUN_DEPENDS',
    'L' => 'LIB_DEPENDS',
    'F' => 'FETCH_DEPENDS',
    'E' => 'EXTRACT_DEPENDS',
    'P' => 'PATCH_DEPENDS'
  );

  return $depends{$depends_type};
}

sub update_depends_helper {
	# for this depends, put it into the db
	my $this = shift;

	my $CommitBranch = shift;
	my $depends      = shift;
	my $depends_type = shift;

	my $dependent;
	
	print "depends with this: '$depends'\n";
	if ( $depends eq '' )
	{
	  print "no depends to look for; returning\n";
	  return;
	}

  my $SVNDIR_CHROOT = FreshPorts::Branches::GetPathToRepoForBranchCHROOT($CommitBranch);

  # this magic courtesy of Ade Lovett
  # NOTE: this removes duplicates
  my @depends_list = uniq( map { s/^.*$SVNDIR_CHROOT\///;$_ } split(/ /, $depends) );
  print "The '" . $depends_type . "' depends are: ";
  print join(' - ', @depends_list) . "\n";

  my $port_dependencies = FreshPorts::PortDependencies->new( $this->{dbh} );

  foreach $dependent (@depends_list) {
    print 'adding in ' . $dependent . "\n";
    $port_dependencies->{port_name}           = $this->{category} . '/' . $this->{name};
    $port_dependencies->{port_name_dependent} = $dependent;
    $port_dependencies->{depends_type}        = $depends_type;
    if ( $port_dependencies->insert() )
    {
      # it worked
    }
    else
    {
      # we do not report unfound dependencies on branches.  They often haven't hadd a commitin the branch, and hence are not in the FreshPorts database
      if ($CommitBranch eq $FreshPorts::Constants::HEAD) {
        FreshPorts::CommitterOptIn::RecordErrorDetails("$this->{category}/$this->{name}", "NOTE: this particular sanity test is very experimental\nA port specified in the " . $this->depends_type_long( $depends_type ) . " of " . $this->{category} . '/' . $this->{name} . " does not exist: '" . $dependent . "' on branch '$CommitBranch'.\n\n");
      }
    }
  }
}

sub depends_stripper {
  my $this    = shift;
  my $depends = shift;

  my $newdepends = '';

  # if it not defined, return an empty string  
  if ( !defined($depends) || $depends eq '')
  {
    print "no depends found\n";
    return $newdepends;
  }

  print "1depends: $depends\n";
  
  foreach my $dep (split(/\s+/, $depends))
  {
    print "Now splitting: '$dep'\n";
    my ($d, $ddir) = split(/:/, $dep);
    if (!defined($ddir) || $depends eq 'DEPENDS')
    {
      $ddir = $d;
    }

    if ($newdepends)
    {
      $newdepends .= " ";
    }

    my $absdir = $this->_GetRealPath($ddir);
    if (defined($absdir))
    {
      if ( $absdir ne $ddir )
      {
        if ($absdir == 0)
        {
          print "that path does not exist\n";
          # set things back to what we had, so the error can process correctly
          $absdir = $ddir;
        }
        else
        {
          print "converted '$ddir' to '$absdir'\n";
        }
      }

      $newdepends .= "$d:$absdir";
    }
    else
    {
      # this should be a sanity test failure?
      print "Oh.  Umm.  No, that does not translate into a valid dependency.  Skipping....\n";
      FreshPorts::CommitterOptIn::RecordErrorDetails("$this->{category}/$this->{name}", "\nI could not translate the following into a dependency: '$dep'");
    }
  }

  print "2depends: $newdepends\n";
  return $newdepends;
}


FreshPorts::Utilities::InitSyslog();

1;
