#!/usr/local/bin/perl -w
#
# $Id: port.pm,v 1.73 2013-04-24 12:22:43 dan Exp $
#
#
# Copyright (c) 2001-2005 DVL Software
#

package FreshPorts::Port;

# for https://github.com/FreshPorts/freshports/issues/455
use open ':std', ':encoding(UTF-8)';

require Exporter;
require FreshPorts::config;
require FreshPorts::element;
require FreshPorts::utilities;
require FreshPorts::committer_opt_in;
require FreshPorts::port_dependencies;
require FreshPorts::branches;
require FreshPorts::ports_generate_plist;
require FreshPorts::package_flavors;

use strict;
use FreshPorts::config;
use FreshPorts::constants;

# added to catch errors when printing SQL
use Try::Tiny;

# for Ade's special code in update_depends_helper
use List::MoreUtils qw(uniq);

# for testing results from file existance
use Scalar::Util qw(looks_like_number);

# for testing dates, as recommended by "B. Estrade" <estrabd@gmail.com>
use POSIX qw/strftime/;

# =================================

sub _initialize {
	my $this = shift;

	$this->{portname}             = '';
	$this->{name}                 = '';
	$this->{short_description}    = '';
	$this->{long_description}     = '';
	$this->{version}              = '';
	$this->{revision}             = '';
	$this->{maintainer}           = '';
	$this->{homepage}             = '';
	$this->{master_sites}         = '';
	$this->{extract_suffix}       = '';
	$this->{package_exists}       = '';
	$this->{depends_build}        = '';
	$this->{depends_run}          = '';
	$this->{depends_lib}          = '';
	$this->{forbidden}            = '';
	$this->{broken}               = '';
	$this->{deprecated}           = '';
	$this->{ignore}               = '';
	$this->{master_port}          = '';
	$this->{latest_link}          = '';
	$this->{no_latest_link}       = '';
	$this->{no_package}           = '';
	$this->{package_name}         = '';
	$this->{portepoch}            = '';
	$this->{restricted}           = '';
	$this->{no_cdrom}             = '';
	$this->{expiration_date}      = '';
	$this->{is_interactive}       = '';
	$this->{only_for_archs}       = '';
	$this->{not_for_archs}        = '';
	$this->{status}               = '';
	$this->{showconfig}           = '';
	$this->{license}              = '';
	$this->{fetch_depends}        = '';
	$this->{extract_depends}      = '';
	$this->{patch_depends}        = '';
	$this->{test_depends}         = '';
	$this->{uses}                 = '';
	$this->{pkgmessage}           = '';
	$this->{distinfo}             = '';
	$this->{license_restricted}   = '';
	$this->{manual_package_build} = '';
	$this->{license_perms}        = '';
	$this->{conflicts}            = '';
	$this->{conflicts_build}      = '';
	$this->{conflicts_install}    = '';
	$this->{options_name}         = '';
	$this->{generate_plist}       = '';
	$this->{makefile}             = '';

	$this->{categories}           = '';
	$this->{element_pathname}     = '';
}

sub _GetValuesFromRow {
	my $this = shift;
	my $row  = shift;

	$this->{id}                    = $row->{id};
	$this->{element_id}            = $row->{element_id};
	$this->{category_id}           = $row->{category_id};
	$this->{category}              = $row->{category};
	$this->{name}                  = $row->{name};

	$this->{short_description}     = $row->{short_description};
	$this->{long_description}      = $row->{long_description};
	$this->{version}               = $row->{version};
	$this->{revision}              = $row->{revision};
	$this->{maintainer}            = $row->{maintainer};
	$this->{homepage}              = $row->{homepage};
	$this->{master_sites}          = $row->{master_sites};
	$this->{extract_suffix}        = $row->{extract_suffix};
	$this->{package_exists}        = $row->{package_exists};
	$this->{depends_build}         = $row->{depends_build};
	$this->{depends_run}           = $row->{depends_run};
	$this->{depends_lib}           = $row->{depends_lib};
	$this->{forbidden}             = $row->{forbidden};
	$this->{broken}                = $row->{broken};
	$this->{deprecated}            = $row->{deprecated};
	$this->{ignore}                = $row->{ignore};
	$this->{master_port}           = $row->{master_port};
	$this->{latest_link}           = $row->{latest_link};
	$this->{no_latest_link}        = $row->{no_latest_link};
	$this->{no_package}            = $row->{no_package};
	$this->{package_name}          = $row->{package_name};
	$this->{portepoch}             = $row->{portepoch};
	$this->{restricted}            = $row->{restricted};
	$this->{no_cdrom}              = $row->{no_cdrom};
	$this->{expiration_date}       = $row->{expiration_date};
	$this->{is_interactive}        = $row->{is_interactive};
	
	$this->{only_for_archs}        = $row->{only_for_archs};
	$this->{not_for_archs}         = $row->{not_for_archs};
	$this->{status}                = $row->{status};
	$this->{showconfig}            = $row->{showconfig};
	$this->{license}               = $row->{license};
	$this->{fetch_depends}         = $row->{fetch_depends};
	$this->{extract_depends}       = $row->{extract_depends};
	$this->{patch_depends}         = $row->{patch_depends};
	$this->{test_depends}          = $row->{test_depends};
	$this->{uses}                  = $row->{uses};
	$this->{pkgmessage}            = $row->{pkgmessage};
	$this->{distinfo}              = $row->{distinfo};
	$this->{license_restricted}    = $row->{license_restricted};
	$this->{manual_package_build}  = $row->{manual_package_build};
	$this->{license_perms}         = $row->{license_perms};
	$this->{conflicts}             = $row->{conflicts};
	$this->{conflicts_build}       = $row->{conflicts_build};
	$this->{conflicts_install}     = $row->{conflicts_install};
	$this->{options_name}          = $row->{options_name};
	$this->{generate_plist}        = $row->{generate_plist};
	$this->{makefile}              = $row->{makefile};

	$this->{categories}            = $row->{categories};
	$this->{last_commit_id}        = $row->{last_commit_id};
	$this->{element_pathname}      = $row->{element_pathname};
}

# =================================

sub new {
	my $this          = {};
	my $class         = shift;

	$this->{dbh}      = shift;
	$this->{RepoType} = shift;

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

	print "into FreshPorts::Port::_save\n";

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
   set short_description    = " . $dbh->quote($this->{short_description})                                   . ",
       long_description     = " . $dbh->quote($this->{long_description})                                    . ", 
       version              = " . $dbh->quote($this->{version})                                             . ", 
       revision             = " . $dbh->quote($this->{revision})                                            . ", 
       maintainer           = " . $dbh->quote($this->{maintainer})                                          . ", 
       homepage             = " . FreshPorts::Utilities::NULLIfEmpty($dbh, $this->{homepage})               . ", 
       master_sites         = " . FreshPorts::Utilities::NULLIfEmpty($dbh, $this->{master_sites})           . ", 
       extract_suffix       = " . $dbh->quote($this->{package_exists})                                      . ", 
       depends_build        = " . FreshPorts::Utilities::NULLIfEmpty($dbh, $this->{depends_build})          . ", 
       depends_run          = " . FreshPorts::Utilities::NULLIfEmpty($dbh, $this->{depends_run})            . ", 
       depends_lib          = " . FreshPorts::Utilities::NULLIfEmpty($dbh, $this->{depends_lib})            . ", 
       forbidden            = " . FreshPorts::Utilities::NULLIfEmpty($dbh, $this->{forbidden})              . ", 
       broken               = " . FreshPorts::Utilities::NULLIfEmpty($dbh, $this->{broken})                 . ", 
       deprecated           = " . FreshPorts::Utilities::NULLIfEmpty($dbh, $this->{deprecated})             . ", 
       ignore               = " . FreshPorts::Utilities::NULLIfEmpty($dbh, $this->{ignore})                 . ", 
       master_port          = " . FreshPorts::Utilities::NULLIfEmpty($dbh, $this->{master_port})            . ",
       latest_link          = " . FreshPorts::Utilities::NULLIfEmpty($dbh, $this->{latest_link})            . ", 
       no_latest_link       = " . FreshPorts::Utilities::NULLIfEmpty($dbh, $this->{no_latest_link})         . ", 
       no_package           = " . FreshPorts::Utilities::NULLIfEmpty($dbh, $this->{no_package})             . ", 
       package_name         = " . FreshPorts::Utilities::NULLIfEmpty($dbh, $this->{package_name})           . ", 
       portepoch            = " . FreshPorts::Utilities::NULLIfEmpty($dbh, $this->{portepoch})              . ", 
       restricted           = " . $restricted_alt                                                           . ", 
       no_cdrom             = " . $no_cdrom_alt                                                             . ",  
       expiration_date      = " . $expiration_date_alt                                                      . ", 
       is_interactive       = " . $is_interactive_alt                                                       . ", 
       only_for_archs       = " . $only_for_archs_alt                                                       . ",
       not_for_archs        = " . $not_for_archs_alt                                                        . ",
       showconfig           = " . FreshPorts::Utilities::NULLIfEmpty($dbh, $this->{showconfig})             . ",
       license              = " . $license_alt                                                              . ",
       fetch_depends        = " . FreshPorts::Utilities::NULLIfEmpty($dbh, $this->{fetch_depends})          . ", 
       extract_depends      = " . FreshPorts::Utilities::NULLIfEmpty($dbh, $this->{extract_depends})        . ", 
       patch_depends        = " . FreshPorts::Utilities::NULLIfEmpty($dbh, $this->{patch_depends})          . ", 
       test_depends         = " . FreshPorts::Utilities::NULLIfEmpty($dbh, $this->{test_depends})           . ", 
       uses                 = " . FreshPorts::Utilities::NULLIfEmpty($dbh, $this->{uses})                   . ", 
       pkgmessage           = " . FreshPorts::Utilities::NULLIfEmpty($dbh, $this->{pkgmessage})             . ", 
       distinfo             = " . FreshPorts::Utilities::NULLIfEmpty($dbh, $this->{distinfo})               . ", 
       license_restricted   = " . FreshPorts::Utilities::NULLIfEmpty($dbh, $this->{license_restricted})     . ", 
       manual_package_build = " . FreshPorts::Utilities::NULLIfEmpty($dbh, $this->{manual_package_build})   . ", 
       license_perms        = " . FreshPorts::Utilities::NULLIfEmpty($dbh, $this->{license_perms})          . ", 
       conflicts            = " . FreshPorts::Utilities::NULLIfEmpty($dbh, $this->{conflicts})              . ", 
       conflicts_build      = " . FreshPorts::Utilities::NULLIfEmpty($dbh, $this->{conflicts_build})        . ", 
       conflicts_install    = " . FreshPorts::Utilities::NULLIfEmpty($dbh, $this->{conflicts_install})      . ", 
       options_name         = " . FreshPorts::Utilities::NULLIfEmpty($dbh, $this->{options_name})           . ", 
       makefile             = " . FreshPorts::Utilities::NULLIfEmpty($dbh, $this->{makefile})               . ", 
       categories           = " . FreshPorts::Utilities::NULLIfEmpty($dbh, $this->{categories});


		# we don't always have this value, so we don't change it....
		if (defined($this->{last_commit_id})) {
			$sql .= "\n, last_commit_id		= $this->{last_commit_id}";
		}
		
		$sql .= " where id = $this->{id}";

		try {
			print "sql = $sql\n";
		} catch {
			print "ERROR PRINTING SQL.  Maintainer: '" . $this->{maintainer} . "' homepage: '" . $this->{homepage} . "' package_name: '" . $this->{package_name} . "'\n";
		};
		$sth = $this->{dbh}->prepare($sql);
		$sth->execute ||
			FreshPorts::Utilities::ReportError('warning', "Could not execute SQL $sql ... maybe invalid? " . $dbh->errstr, 1);
	} else {
		# we are inserting
		# do we really need to quote these things?

		if (!$this->{element_id} && $this->{partialpathname}) {
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
          $this->upate_generate_plist($CommitBranch);
          $this->update_package_flavors($CommitBranch);
        }

	print "leaving FreshPorts::Port::_save\n";

	# after savings, return the ID
	return $this->{id};
}

sub Undelete {
	my $this = shift;
	my $dbh  = shift;

	print "into FreshPorts::Port::Undelete\n";
	my $element  = FreshPorts::Element->new($dbh);

	$element->{id}     = $this->{element_id};
	$element->{status} = $FreshPorts::Element::Active;

	$element->update_status();

	# For later, when we are updating ports, mark this port as active.
	$this->SetActive();

	print "leaving FreshPorts::Port::Undelete\n";

	return $this->{id};
}

sub FetchByID {
	my $this	= shift;

	my $dbh;
	my $sql;
	my $sth;
	my $row;

	$dbh = $this->{dbh};

	$sql = "SET CLIENT_ENCODING TO 'ISO-8859-1';
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

	# I enountered trouble with existing data, which would not come back as UTF-8
	# UTF-8 is set on the connection
	$sql = "SET CLIENT_ENCODING TO 'SQL_ASCII';
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
	my $Repository   = shift;
	my $CommitBranch = shift;

	my $makefile; # contents of Makefile for this port

	my $result;
	my $makecommand;
	my $ErrorMessage = '';	# stores the result of the latest make command
	                        # in case we need it for error reporting
	my $OtherErrors  = '';	# gets the results of the TmpFile used to collect errors.

	my $REPODIR;
  	my $REPODIR_CHROOT;

	print "RepoType='$this->{RepoType}'\n";
	print "Repository='$Repository'\n";
	print "CommitBranch='$CommitBranch'\n";
	if ($this->{RepoType}    eq 'git') {
	  print "calling FreshPorts::Branches::GetPathToRepoForBranch\n";
	  $REPODIR        = $FreshPorts::Config::PortsDir;
  	  $REPODIR_CHROOT = $FreshPorts::Config::PortsDir;
        }
        elsif ($this->{RepoType} eq 'svn') {
	  print "calling FreshPorts::Branches::GetPathToRepoForBranchSVN\n";
	  $REPODIR        = FreshPorts::Branches::GetPathToRepoForBranchSVN      ($CommitBranch);
  	  $REPODIR_CHROOT = FreshPorts::Branches::GetPathToRepoForBranchCHROOTSVN($CommitBranch);
        } else {
          die("Unknown RepoType='$this->{RepoType}'");
        }

        # this is a full pathname including the jail dir name
        # we use this to verify the Makefile exists from outside the jail
        #
	my $MakefileDirectory = "$FreshPorts::Config::JailBaseDir$REPODIR/$this->{category}/$this->{name}";

        print "CommitBranch:   '$CommitBranch\n";	
	print "REPODIR:        '$REPODIR'\n";
	print "REPODIR_CHROOT: '$REPODIR_CHROOT'\n";

	# this is relative to the host root, not the ports jail root
	my $Makefile = "$MakefileDirectory/$FreshPorts::Constants::FILE_MAKEFILE";
	
	print "checking to make sure $MakefileDirectory/$FreshPorts::Constants::FILE_MAKEFILE exists\n";

	if (-f $Makefile) {
		# good, the Makefile actually exists.  This should be the case.  If not, something
		# rather unusual is happening.
		print "Phew.  It's here.  Moving on....\n";
	} else {
		print " * * * * not found.  WTF?\n";
		# If the Makefile does not exist, suspect a repocopy.
		# A repocopy is the process of manually moving things around within the cvs repository.
		# This preserves commit history when a port is being renamed, but it makes life difficultJailShowConfigScript
		# for FreshPorts, which only tracks commits.
		# We need the trailing space because there will be another message added right after this one.
		FreshPorts::CommitterOptIn::RecordErrorDetails("$this->{category}/$this->{name}", "I did not find a Makefile for this port, and none was mentioned in the commit.  If a repocopy has been done, please ignore this message. ");
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
	# looks like:   /usr/local/bin/sudo /usr/sbin/jexec /jails/freshports /make-port.sh /usr/ports www/qt5-webkit 2>/tmp/FreshPorts.www.qt5-webkit.make-error.2021.1.3.22
	$makecommand = "/usr/local/bin/sudo /usr/sbin/jexec $FreshPorts::Config::JailName $FreshPorts::Config::JailPortScript $REPODIR_CHROOT $this->{category}/$this->{name} 2>$TmpFile";

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
                my $mastersitescommand = "/usr/local/bin/sudo /usr/sbin/jexec $FreshPorts::Config::JailName $FreshPorts::Config::JailMasterSitesScript $REPODIR_CHROOT $this->{category}/$this->{name} 2>$TmpFile";

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
                my $showconfigcommand = "/usr/local/bin/sudo /usr/sbin/jexec $FreshPorts::Config::JailName $FreshPorts::Config::JailShowConfigScript $REPODIR_CHROOT $this->{category}/$this->{name} 2>$TmpFile";

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

		(my $portname,       my $packagename,        my $descrpath,            my $categories,
		 my $portversion,    my $portrevision,       my $shortdescription,     my $CommentFile,
		 my $maintainer,     my $extractsuffix,      my $builddepends,         my $rundepends,
		 my $libdepends,     my $forbidden,          my $broken,               my $deprecated,
		 my $ignore,         my $master_port,        my $latest_link,          my $no_latest_link,
		 my $no_package,     my $pkgnameprefix,      my $pkgnamesuffix,        my $portepoch,
		 my $restricted,     my $no_cdrom,           my $expiration_date,      my $is_interactive,
		 my $only_for_archs, my $not_for_archs,      my $license,              my $fetchdepends, 
		 my $extractdepends, my $patchdepends,       my $uses,                 my $pkgmessagepath,
		 my $distinfo_file,  my $license_restricted, my $manual_package_build, my $license_perms,
		 my $conflicts,      my $conflicts_build,    my $conflicts_install,    my $options_name,
		 my $homepage,       my $testdepends) = split(/\n/s, $MakeResults);

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
		
		print " rundepends as taken from script '$rundepends'\n";
		
		$builddepends   = FreshPorts::Utilities::trim_multiple_to_single(FreshPorts::Utilities::trim($builddepends));
		$rundepends     = FreshPorts::Utilities::trim_multiple_to_single(FreshPorts::Utilities::trim($rundepends));
		$libdepends     = FreshPorts::Utilities::trim_multiple_to_single(FreshPorts::Utilities::trim($libdepends));
		$fetchdepends   = FreshPorts::Utilities::trim_multiple_to_single(FreshPorts::Utilities::trim($fetchdepends));
		$extractdepends = FreshPorts::Utilities::trim_multiple_to_single(FreshPorts::Utilities::trim($extractdepends));
		$patchdepends   = FreshPorts::Utilities::trim_multiple_to_single(FreshPorts::Utilities::trim($patchdepends));
		$testdepends    = FreshPorts::Utilities::trim_multiple_to_single(FreshPorts::Utilities::trim($testdepends));


		$master_port =~ s|$REPODIR_CHROOT/||;
		
		print " portname                 = '$this->{name}'\n";
		print " packagename              = '$portname'\n";
		print " category                 = '$this->{category}'\n";
		print " packagename              = '$packagename'\n";
		print " homepage                 = '$homepage'\n";
		print " descrpath                = '$descrpath'\n";
		print " categories               = '$categories'\n";
		print " portversion              = '$portversion'\n";
		print " portrevision             = '$portrevision'\n";
		print " comment                  = '$shortdescription'\n";
		print " CommentFile              = '$CommentFile'\n";
		print " maintainer               = '$maintainer'\n";
		print " extractsuffix            = '$extractsuffix'\n";
		print " mastersites              = '$mastersites'\n";
		print " builddepends             = '$builddepends'\n";
		print " rundepends               = '$rundepends'\n";
		print " libdepends               = '$libdepends'\n";
		print " fetchdepends             = '$fetchdepends'\n";
		print " extractdepends           = '$extractdepends'\n";
		print " patchdepends             = '$patchdepends'\n";
		print " testdepends              = '$testdepends'\n";
		print " uses                     = '$uses'\n";
		print " pkgmessagepath           = '$pkgmessagepath'\n";
		print " distinfo_file            = '$distinfo_file'\n";
		print " license_restricted       = '$license_restricted'\n";
		print " manual_package_build     = '$manual_package_build'\n";
		print " license_perms            = '$license_perms'\n";
		print " conflicts                = '$conflicts'\n";
		print " conflicts_build          = '$conflicts_build'\n";
		print " conflicts_install        = '$conflicts_install'\n";
		print " options_name             = '$options_name'\n";

		print "Grabbing make -V DESCR\n";

		# eliminate multiple // : PR 174
		# to compensate for bug in File::PathConvert::realpath (which is no longer used; _GetRealPath)
		$descrpath =~ s|//|/|g;

		my $RealDescrPath = $this->_GetRealPath($descrpath);

		if (!defined($shortdescription)) {
                  die("OK, good, we have no short description");
		}

		# if it's defined, and it exists....
		my $longdescription    = '';
		my $homepage_pkg_descr = '';
		if (looks_like_number($RealDescrPath))
		{
                  print "Description file does not exist: '$descrpath' (result of make -V DESCR)\n";
                  FreshPorts::CommitterOptIn::RecordErrorDetails("$this->{category}/$this->{name}", "Description file does not exist: '$descrpath' (result of make -V DESCR)\n");
	  	}
		else
		{
                   if (defined($RealDescrPath) && $RealDescrPath) {
                      print "invoking _GetDescrAndHomePage() for DESCR with '$RealDescrPath'\n";
                      ($longdescription, $homepage_pkg_descr) = $this->_GetDescrAndHomePage($RealDescrPath);
                   }
		}

		chomp($longdescription); # get rid of the trailing whitespace.

                # For decades, WWW was obtained from pkg-descr, hence the above code extracting said value.
                # 		
		# https://cgit.freebsd.org/ports/commit/?id=b7f05445c00f2625aa19b4154ebcbce5ed2daa52 moved WWW
		# from pkg-descr to Makefile
		#
		# see also https://cgit.freebsd.org/ports/commit/?id=fb16dfecae4a6efac9f3a78e0b759fb7a3c53de4
		#
		# Support for make -V www was added via https://cgit.freebsd.org/ports/commit/?id=ddd0e820c8eb73acef94c72434c382982d0fa329
		#
		# If we didn't get a value from the Makefile, but we did get a value from
		# pkg-descr, use the latter.
		#
		# This allows non-conforming ports to obtain the appropriate value. e.g. ports on 2022Q3
		# Quarterly branch ports won't get this until 2022Q4
		#
		print " homepage_pkg_descr       = '$homepage_pkg_descr'\n";
		if ($homepage eq '') {
                    $homepage = $homepage_pkg_descr;
                    print "\$homepage is empty, using \$homepage_pkg_descr instead\n";
                }

		print "Grabbing make -V PKGMESSAGE\n";
		#
		# make -V PKGMESSAGE
		#
		# [dan@freshports:/usr/ports/sysutils/bacula9-server] $ make -V PKGMESSAGE
		# /usr/ports/sysutils/bacula9-server/work/pkg-message.server

		# eliminate multiple // : PR 174
		# to compensate for bug in File::PathConvert::realpath (which is no longer used; _GetRealPath)
		$pkgmessagepath =~ s|//|/|g;

		print "\$pkgmessagepath='$pkgmessagepath'\n";
		# $pkgmessagepath is relative to the inside of the jail, so no prefix required on this call.
		my $RealPKGMESSAGEPath = '';
		if ($pkgmessagepath ne '') {
		  # avoid invoking _GetRealPath() with an empty string because that logs an error
		  $RealPKGMESSAGEPath = $this->_GetRealPath($pkgmessagepath);
		}
		print "\$RealPKGMESSAGEPath='$RealPKGMESSAGEPath'\n";

		# if it's defined, and it exists....
		my $pkgmessage = '';
		if (looks_like_number($pkgmessagepath))
		{
                  print "PKGMESSAGE file does not exist: '$pkgmessagepath' (result of make -V PKGMESSAGE)\n";
                  FreshPorts::CommitterOptIn::RecordErrorDetails("$this->{category}/$this->{name}", "PKGMESSAGE file does not exist: '$pkgmessagepath' (result of make -V PKGMESSAGE)\n");
	  	}
		else
		{
                   print "pkgmessagepath does look like a valid file to me: '$pkgmessagepath' (result of make -V PKGMESSAGE)\n";
                   if ($RealPKGMESSAGEPath) {
                      print "invoking _GetFileContentsFromJail() for PKGMESSAGE with '$RealPKGMESSAGEPath'\n";
                      $pkgmessage = $this->_GetFileContentsFromJail($RealPKGMESSAGEPath);
                   } else {
                      print "but _GetRealPath() claims that file does not exist. Perhaps it is '*/work/pkg-message.in' or similar\n";
                      # we are looking for /work/ or /work-default/, etc, the 'default' is various package flavors 
                      if ($pkgmessagepath =~ '/work(?:-.*)?/') {
                         print "Yes, yes it does contain '/work/' - let's try a make configure\n";
                         $makecommand = "/usr/local/bin/sudo /usr/sbin/jexec $FreshPorts::Config::JailName $FreshPorts::Config::JailPkgMessage $REPODIR_CHROOT $this->{category}/$this->{name} $pkgmessagepath 2>$TmpFile";
                         print "makecommand = $makecommand\n";
                         $pkgmessage=`$makecommand`;
                         $result = $?;
                         print 'Result = ' . $result . "\n";
                         
                         if ($result == 0) {
                           print "success, we have\n'$pkgmessage'\n";
                         } else {
                           print "FAILUSER, we could not locate\n'$pkgmessage'\n";
                         }
                      } else {
                         print "No, that is not a /work/ pkg-message. There is no pkg-message for this port at all\n";
                      }# in /work/
                   } # else not RealPKGMESSAGEPath
		} # pkgmessagepath is not a number

		chomp($pkgmessage); # get rid of the trailing whitespace.

		my $RealDistInfoFilePath = $this->_GetRealPath($distinfo_file);
		# if it's defined, and it exists....
		my $distinfo = '';
		if (looks_like_number($RealDistInfoFilePath))
		{
		   # this is never an error.  Some ports do not have dist files
		   print "DISTINFO_FILE file does not exist: '$distinfo_file' (result of make -V DISTINFO_FILE)\n";
	  	}
		else
		{
                   if (defined($RealDistInfoFilePath) && $RealDistInfoFilePath) {
                      print "invoking _GetFileContentsFromJail() for DISTINFO with '$RealDistInfoFilePath'\n";
                      $distinfo = $this->_GetFileContentsFromJail($RealDistInfoFilePath);
#                      print "back from _GetFileContentsFromJail with '$distinfo'\n";
                   }
		}
		chomp($distinfo); # get rid of the trailing whitespace.

		print "extracting Makefile contents for full test searching\n";
		# this is relative to the host root, not the ports jail root
		print "\$Makefile='$Makefile'\n";
		# Let's pull in the Makefile file for full text searching
		if (defined($Makefile) && $Makefile) {
		  print "invoking _GetFileContents() for Makefile with '$Makefile'\n";
		  $makefile = $this->_GetFileContents($Makefile);
#		  print "back from _GetFileContentsFromJail with '$makefile'\n";
		} else {
		  print "Sorry kids, '$Makefile' doesn't look good to me\n";
		}
		chomp($makefile); # get rid of the trailing whitespace.



		# extract the generate_plist contents
		my $configure_plist_command = "/usr/local/bin/sudo /usr/sbin/jexec $FreshPorts::Config::JailName $FreshPorts::Config::JailConfigurePlist $REPODIR_CHROOT $this->{category}/$this->{name} 2>$TmpFile";

		print "generate_plist_command = $configure_plist_command\n";

		my $generate_plist = `$configure_plist_command`;
		# save this for later reference ... we don't actually use it...
		$result = $?;
		print 'Result = ' . $result . "\n";

		chomp($generate_plist); # get rid of the trailing whitespace.



		# extract the package flavors
		my $package_flavors_command = "/usr/local/bin/sudo /usr/sbin/jexec $FreshPorts::Config::JailName $FreshPorts::Config::JailPackageFlavors $REPODIR_CHROOT $this->{category}/$this->{name} 2>$TmpFile";

		print "package_flavors_command = $package_flavors_command\n";

		my $package_flavors = `$package_flavors_command`;
		# save this for later reference ... we don't actually use it
		$result = $?;
		print 'Result = ' . $result . "\n";
		chomp($package_flavors); # get rid of the trailing whitespace.

		print 'size is ' . -s $TmpFile;
		print "\n";


		if (-s $TmpFile > 0) {
			print "getting error message from temp file\n";
			$ErrorMessage = "Error message is: " . `cat $TmpFile`;
		}

		# remove that error collection file
		unlink($TmpFile);


		# show some results
		print "12x \$generate_plist      = '$generate_plist'\n";
		print "12y \$package_flavors     = '$package_flavors'\n";
		print "12z \$makefile            = '$makefile'\n";

		print "12 \$shortdescription     = '$shortdescription'\n";
		print "13 \$longdescription      = '$longdescription'\n";
		print "14 \$homepage             ='";
		if (defined($homepage)) {
			print "$homepage";
		}
		print "'\n";

		print "16 \$forbidden            = '$forbidden'\n";
		print "17 \$broken               = '$broken'\n";
		print "18 \$deprecated           = '$deprecated'\n";
		print "19 \$ignore               = '$ignore'\n";
		print "20 \$master_port          = '$master_port'\n";
		print "21 \$latest_link          = '$latest_link'\n";
		print "22 \$no_latest_link       = '$no_latest_link'\n";
		print "23 \$no_package           = '$no_package'\n";
		print "24 \$package_name         = '$package_name'\n";
		print "25 \$portepoch            = '$portepoch'\n";
		print "26 \$restricted           = '$restricted'\n";
		print "27 \$no_cdrom             = '$no_cdrom'\n";
		print "28 \$expiration_date      = '$expiration_date'\n";
		print "29 \$is_interactive       = '$is_interactive'\n";
		print "30 \$only_for_archs       = '$only_for_archs'\n";
		print "31 \$not_for_archs        = '$not_for_archs'\n";
		print "32 \$categories           = '$categories'\n";
		print "33 \$showconfig           = '$showconfig'\n";
		print "34 \$license              = '$license'\n";
		print "35 \$fetchdepends         = '$fetchdepends'\n";
		print "36 \$extractdepends       = '$extractdepends'\n";
		print "37 \$patchdepends         = '$patchdepends'\n";
		print "38 \$testdepends          = '$testdepends'\n";
		print "39 \$uses                 = '$uses'\n";
		print "41 \$pkgmessage           = '$pkgmessage'\n";
		print "42 \$distinfo             = '$distinfo'\n";
		print "43 \$license_restricted   = '$license_restricted'\n";
		print "44 \$manual_package_build = '$manual_package_build'\n";
		print "45 \$license_perms        = '$license_perms'\n";
		print "46 \$conflicts            = '$conflicts'\n";
		print "47 \$conflicts_build      = '$conflicts_build'\n";
		print "48 \$conflicts_install    = '$conflicts_install'\n";
		print "49 \$options_name         = '$options_name'\n";

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

		$this->{portname}		= $portname;
		$this->{short_description}	= $shortdescription;
		$this->{long_description}	= $longdescription;
		$this->{version}		= $portversion;
		$this->{revision}		= $portrevision;
		$this->{maintainer}		= $maintainer;
		$this->{homepage}		= $homepage;
		$this->{master_sites}		= $mastersites;
		$this->{extract_suffix}		= $extractsuffix;
		$this->{depends_build}		= $builddepends;
		$this->{depends_run}		= $rundepends;
		$this->{depends_lib}		= $libdepends;
		$this->{forbidden}		= $forbidden;
		$this->{broken}			= $broken;
		$this->{deprecated}		= $deprecated;
		$this->{ignore}			= $ignore;
		$this->{master_port}		= $master_port;
		$this->{latest_link}		= $latest_link;
		$this->{no_latest_link}		= $no_latest_link;
		$this->{no_package}		= $no_package;
		$this->{package_name}		= $package_name;
		$this->{portepoch}		= $portepoch;
		$this->{restricted}		= $restricted;
		$this->{no_cdrom}		= $no_cdrom;
		$this->{expiration_date}	= $expiration_date;
		$this->{is_interactive}		= $is_interactive;
		$this->{only_for_archs}		= $only_for_archs;
		$this->{not_for_archs}		= $not_for_archs;
		$this->{showconfig} 		= $showconfig;
		$this->{license}                = $license;
		$this->{categories}	        = $categories;
		$this->{fetch_depends}		= $fetchdepends;
		$this->{extract_depends}	= $extractdepends;
		$this->{patch_depends}		= $patchdepends;
		$this->{test_depends}		= $testdepends;
		$this->{uses}	    		= $uses;
		$this->{pkgmessage} 		= $pkgmessage;
		$this->{distinfo}		= $distinfo;
		$this->{license_restricted}	= $license_restricted;
		$this->{manual_package_build}	= $manual_package_build;
		$this->{license_perms}		= $license_perms;
		$this->{conflicts}		= $conflicts;
		$this->{conflicts_install}	= $conflicts_install;
		$this->{options_name}	        = $options_name;
		$this->{conflicts_build}	= $conflicts_build;
		$this->{generate_plist}		= $generate_plist;
		$this->{makefile}		= $makefile;
		# convert all whitespace to a single space
		# This arose from 200609130717.k8D7HpNc057638@repoman.freebsd.org
		#
		$this->{categories}		=~ s/\s+/ /g;
		
		$this->{package_flavors}	= $package_flavors;

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
	my $this     = shift;
	my $result   = 0;
	my $ErrorMsg = '';

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
	# to be pure, we should do this as a script in the jail-root, but we'd have to call two scripts:
	# one for the homepage, one for the description.
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
sub _GetFileContentsFromJail($) {
	my $this = shift;
	my $file = shift;

	return $this->_GetFileContents($FreshPorts::Config::JailBaseDir . $file);
}


# =================================
sub _GetFileContents($) {
	my $this = shift;
	my $file = shift;
	my $filecontents;

	print "about to read from " . $file . "\n";

	$filecontents = "";
	# this needs to open relative to the jail root.
	# to be pure, we should do this as a script in the jail-root
	if (open (F, $file))
	{
	
	  while(<F>){
		$filecontents .= $_;
	   }

	   close F;
	} else {
          print "Unable to open '$file'\n";
          FreshPorts::CommitterOptIn::RecordErrorDetails("$this->{category}/$this->{name}", "Unable to open '$file'\n");
	}

	print "here is what we have: $filecontents\n";	

	return $filecontents;
}


# =================================
sub _GetRealPath($) {
	my $this = shift;
  	my $file = shift;

  	if ($file eq '') {
  	  Sys::Syslog::syslog('warning', "_GetRealPath was handed an empty file name");
  	  return '';
  	}

	# invoke realpath on the supplied filename, from within our chroot
	my $makecommand = "/usr/local/bin/sudo /usr/sbin/jexec $FreshPorts::Config::JailName $FreshPorts::Config::JailRealPath $file";

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



sub RefreshFromFiles($;$;$) {
#
# refresh this port based on the files associated with it.
# $fetch_files must be 0
# returns 0 for success, 1 for failure
#
	my $this          = shift;
	my $Repository    = shift;
	my $CommitBranch  = shift; # something like: head or branches/2020Q3

	print "into RefreshFromFiles()\n";
	print "working with repo='$Repository'\n";
	print "working on CommitBranch='$CommitBranch'\n";
	
	# this function used to do a lot more than it does now.
        
	my $result = 0;
	my $error;

	$error = $this->_ExtractValuesFromMakefile($Repository, $CommitBranch);

	if ($error) {
		$result = 1;
	}

	print "leaving RefreshFromFiles()\n";
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

sub upate_generate_plist {
  # for each of the depends in this port, update the ports_dependencies relationships
  my $this = shift;

  my $CommitBranch = shift;

  my $generate_plist = FreshPorts::Ports_generate_plist->new( $this->{dbh} );
  
  $generate_plist->save($this->{id}, $this->{generate_plist});
  
}

sub update_package_flavors {
  # for each of the flavors, add a row to the table
  my $this = shift;

  my $CommitBranch = shift;

  print "update_package_flavors: first step, delete any existing flavors\n";
  my $package_flavors = FreshPorts::PackageFlavors->new( $this->{dbh} );

  # we delete existing flavor information for this port before adding
  $package_flavors->{port_id} = $this->{id};
  $package_flavors->delete();
  
  if (!defined($this->{package_flavors})) {
    print "update_package_flavors: no flavors, leaving\n";
    return;
  }
  
  my $flavor_number = 0;
  my (@lines) = split("\n", $this->{package_flavors});
  foreach my $line (@lines) {
    print "processing: $flavor_number $line\n";
    
    my ($flavor, $flavor_name) = split(/ /, $line);
    
    print "saving: $flavor_number $flavor $flavor_name\n";
    $package_flavors->{port_id}       = $this->{id};
    $package_flavors->{flavor}        = $flavor;
    $package_flavors->{flavor_name}   = $flavor_name;
    $package_flavors->{flavor_number} = $flavor_number;
    
    $package_flavors->add();
    $flavor_number++;
  }
  #  foreach $flavor
}

sub update_depends {
  # for each of the depends in this port, update the ports_dependencies relationships
  my $this = shift;

  my $CommitBranch = shift;

  my $port_dependencies = FreshPorts::PortDependencies->new( $this->{dbh} );
  
  print 'about to delete port_dependencies for id ' . $this->{id} . "\n";
  $port_dependencies->{port_id} = $this->{id};
  $port_dependencies->delete();

  $this->update_depends_helper( $CommitBranch, $this->{depends_build},   'B' ); # build
  $this->update_depends_helper( $CommitBranch, $this->{depends_run},     'R' ); # runtime
  $this->update_depends_helper( $CommitBranch, $this->{depends_lib},     'L' ); # library
  $this->update_depends_helper( $CommitBranch, $this->{fetch_depends},   'F' ); # fetch
  $this->update_depends_helper( $CommitBranch, $this->{extract_depends}, 'E' ); # extract
  $this->update_depends_helper( $CommitBranch, $this->{patch_depends},   'P' ); # patch
  $this->update_depends_helper( $CommitBranch, $this->{test_depends},    'T' ); # test
}

sub depends_type_long {
  my $this = shift;
  my $depends_type = shift;  

  my %depends = (
    'B' => 'BUILD_DEPENDS',
    'T' => 'TEST_DEPENDS',
    'R' => 'RUN_DEPENDS',
    'L' => 'LIB_DEPENDS',
    'F' => 'FETCH_DEPENDS',
    'E' => 'EXTRACT_DEPENDS',
    'P' => 'PATCH_DEPENDS'
  );

  return $depends{$depends_type};
}

sub update_depends_helper {
  #
  # Take a space-separated list of depends and insert them into the database
  # e.g. py27-setuptools>0:devel/py27-setuptools /usr/local/bin/python2.7:lang/python27
  #
  my $this = shift;

  my $CommitBranch = shift;
  my $depends      = shift;
  my $depends_type = shift;

  my $depend;
  my $dependent;

  if ( !defined($depends) || $depends eq '' )
  {
    print "no depends to look for; returning\n";
    return;
  }

  print "depends with this: '$depends'\n";

  # this magic courtesy of Ade Lovett
  # with a tweak on 2017.12.15 from https://gist.github.com/ktracer
  # NOTE: this removes duplicates
  my @depends_list = uniq( map { s/^[^:]+://;$_ } split(/ /, $depends) );
  print "The '" . $depends_type . "' depends are: ";
  print join(' - ', @depends_list) . "\n";

  my $port_dependencies = FreshPorts::PortDependencies->new( $this->{dbh} );

  foreach $depend (@depends_list) {
    print "adding in '$depend'\n";
    
    # a dependant might be of the form:
    #
    # * devel/py-setuptools@py27 - a flavour, see https://wiki.freebsd.org/Ports/FlavorsTools
    # * devel/git:configure - which says git is only needed during the configure phase - see https://www.freebsd.org/doc/en_US.ISO8859-1/books/porters-handbook/makefile-depend.html
    # 
    # So we need to split them on either : or @
    #
    ($dependent, undef) = split /[@\:]/, $depend;
    
    if (!defined($dependent)) {
      FreshPorts::Utilities::ReportError('warning', "Could not split dependent '$depend ... maybe invalid? ", 1);
      continue;
    }

    print " which converts to '$dependent'\n";
    
    
    $port_dependencies->{port_name}           = $this->{category} . '/' . $this->{name};
    $port_dependencies->{port_name_dependent} = $dependent;
    $port_dependencies->{depends_type}        = $depends_type;
    if ( $port_dependencies->insert() )
    {
      # it worked
    }
    else
    {
      # we do not report unfound dependencies on branches.  Such ports on branches often haven't had a commit in the branch, and hence are not in the FreshPorts database
      if ($CommitBranch eq $FreshPorts::Constants::HEAD) {
        FreshPorts::CommitterOptIn::RecordErrorDetails("$this->{category}/$this->{name}", "NOTE: this particular sanity test is very experimental\nA port specified in the " . $this->depends_type_long( $depends_type ) . " of " . $this->{category} . '/' . $this->{name} . " does not exist: '" . $dependent . "' on branch '$CommitBranch'.\n\n");
      }
    }
  }
}

sub _addMissingPORTSDIR {
  my $this     = shift;
  my $depends  = shift;
  my $PortsDir = shift;
  
  print "in _addMissingPORTSDIR(),      we start  with '$depends'\n";
  
  # We prepend ${PORTSDIR} to $depends if not already present

  if ($depends =~ /^$PortsDir/)
  {
    print "I found '$depends' already starts with '$PortsDir'\n";
  }
  else
  {
    print "I am prepending '$depends' with '$PortsDir'\n";
    $depends = "$PortsDir/$depends";
  }

  print "in _addMissingPORTSDIR(),      we finish with '$depends'\n";

  return $depends;
}

sub CreatePortOnBranch {
  my $this          = shift;
  my $category_name = shift;
  my $port_name     = shift;
  my $CommitBranch  = shift;

  my $dbh = $this->{dbh}; # just a short cut...
  my $sth;
  my $sql;
  my @row;

  $sql = 'select CreatePort(' . $dbh->quote($category_name) . ', ' . $dbh->quote($port_name) . ', ' . $dbh->quote($CommitBranch) . ')';
  $sth = $this->{dbh}->prepare($sql);
  $sth->execute ||
    FreshPorts::Utilities::ReportError('warning', "Could not execute SQL $sql ... maybe invalid? " . $dbh->errstr, 1);
    
  @row = $sth->fetchrow_array();
  $sth->finish();
  
  $this->{id} = $row[0];
  
  return $this->{id};
}


FreshPorts::Utilities::InitSyslog();

1;
