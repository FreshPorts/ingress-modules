#!/usr/bin/perl
#
# $Id: port.pm,v 1.44 2007-10-16 18:54:41 dan Exp $
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

use Cwd;
use strict;
use config;
use constants;

sub freshports_ConvertPortPathToStandardLocation($) {
	my $pathname = shift;

	# look for $FreshPorts::Config::path_to_tree and 
	# replace it with /usr.  Why? so we refer to the 
	# real ports tree and not the one we are using

	$pathname =~ s/$FreshPorts::Config::path_to_tree/$FreshPorts::Constants::UsualPortsTreeLocation/g;

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

	$this->{categories}			= '';
	$this->{status}				= '';
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

	$this->{categories}			= $row->{categories};
	$this->{last_commit_id}		= $row->{last_commit_id};
	$this->{status}				= $row->{status};
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

sub save {
	my $this = shift;

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

	if ($this->{id}) {
		# we are updating

		if (!defined($this->{expiration_date}) || $this->{expiration_date} eq '') {
			$expiration_date_alt = 'NULL';
		} else {
			$expiration_date_alt   = $dbh->quote($this->{expiration_date});
		}

		if (!defined($this->{is_interactive}) || $this->{is_interactive} eq '' || 
			$this->{is_interactive} ne 'yes') {
			$is_interactive_alt = 'false';
		} else {
			$is_interactive_alt = 'true';
		}

		$not_for_archs_alt  = $this->_NULLIfEmpty($this->{not_for_archs});
		$only_for_archs_alt = $this->_NULLIfEmpty($this->{only_for_archs});


# correct this sql to update all fields...

		$sql = "
update ports  
   set short_description = " . $dbh->quote($this->{short_description})	. ", 
       long_description  = " . $dbh->quote($this->{long_description})	. ", 
       version           = " . $dbh->quote($this->{version})			. ", 
       revision          = " . $dbh->quote($this->{revision})			. ", 
       maintainer        = " . $dbh->quote($this->{maintainer})			. ", 
       homepage          = " . $dbh->quote($this->{homepage})			. ", 
       master_sites      = " . $dbh->quote($this->{master_sites})		. ", 
       extract_suffix    = " . $dbh->quote($this->{package_exists})		. ", 
       depends_build     = " . $dbh->quote($this->{depends_build})		. ", 
       depends_run       = " . $dbh->quote($this->{depends_run})		. ", 
       depends_lib       = " . $dbh->quote($this->{depends_lib})		. ", 
       forbidden         = " . $dbh->quote($this->{forbidden})			. ", 
       broken            = " . $dbh->quote($this->{broken})				. ", 
       deprecated        = " . $dbh->quote($this->{deprecated})			. ", 
       ignore            = " . $dbh->quote($this->{ignore})				. ", 
       master_port       = " . $dbh->quote($this->{master_port})		. ",
       latest_link       = " . $dbh->quote($this->{latest_link})		. ", 
       no_latest_link    = " . $dbh->quote($this->{no_latest_link})		. ", 
       no_package        = " . $dbh->quote($this->{no_package})			. ", 
       package_name      = " . $dbh->quote($this->{package_name})		. ", 
       portepoch         = " . $dbh->quote($this->{portepoch})			. ", 
       restricted        = " . $dbh->quote($this->{restricted})			. ", 
       no_cdrom          = " . $dbh->quote($this->{no_cdrom})			. ", 
       expiration_date   = " . $expiration_date_alt				    	. ", 
       is_interactive    = " . $dbh->quote($this->{is_interactive})		. ", 
       only_for_archs    = " . $only_for_archs_alt                      . ",
       not_for_archs     = " . $not_for_archs_alt                       . ",
       categories        = " . $dbh->quote($this->{categories});

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

		if (!$this->{element_id} || !$this->{category_id}) {
			FreshPorts::Utilities::ReportError('warning', "Cannot create new port.  Insufficient data", 1);
		}

		#
		# update this sql to insert all fields?

		$this->{id} = FreshPorts::Database::GetNextValue($FreshPorts::Constants::ports_seq, $dbh);

		$sql = "insert into ports (id, element_id, category_id) values ( \
				$this->{id}, \
				$this->{element_id}, \ 
				$this->{category_id})";

		print "sql is $sql\n";

		$sth = $this->{dbh}->prepare($sql);
		if (!$sth->execute) {
			FreshPorts::Utilities::ReportError('warning', "Could not execute SQL $sql ... maybe invalid? " . $dbh->errstr, 1);
		}

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
          element.status,
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
          element.status,
          element_pathname(element.id, FALSE) as element_pathname
     from ports, categories, element
    where ports.element_id  = $this->{element_id}
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
	$element->{pathname} = "$FreshPorts::Config::ports_prefix/$this->{partialpathname}";
	$this->{element_id} = $element->FetchByName();

	return $this->{element_id};
}



sub _ExtractValuesFromMakefile {
	#
	# returns 0 for success, -1 for failure
	#

	my $this = shift;

	my $result;
	my $makecommand;
	my $ErrorMessage = '';	# stores the result of the latest make command
							# in case we need it for error reporting
	my $OtherErrors  = '';	# gets the results of the TmpFile used to collect errors.

	my $MakefileDirectory = "$FreshPorts::Config::path_to_ports/$this->{category}/$this->{name}";

	my $Makefile = "$MakefileDirectory/$FreshPorts::Constants::FILE_MAKEFILE";

	if (-f $Makefile) {
		# good, the Makefile actually exists.  This should be the case.  If not, something
		# rather unusual is happening.
	} else {
		# If the Makefile does not exist, suspect a repocopy.
		# A repocopy is the process of manually moving things around within the cvs repository.
		# This preserves commit history when a port is being renamed, but it makes life difficult
		# for FreshPorts, which only tracks commits.
		FreshPorts::CommitterOptIn::RecordErrorDetails("$this->{category}/$this->{name}", "I did not find a Makefile for this port, and none was mentioned in the commit.  If a repocopy has been done, please ignore this message.");
	}

	my $TmpFile = FreshPorts::Utilities::TmpFileName("$this->{category}.$this->{name}.make-error");

	if (!LooksLikeAMakefile($Makefile)) {
		FreshPorts::CommitterOptIn::RecordErrorDetails("$this->{category}/$this->{name}", "The Makefile fetched via cvsweb did not have filetype==ASCII. Such errors are usually temporary.  FreshPorts will try again later.");
		FreshPorts::Utilities::ReportError('warning', "$Makefile does not look like a makefile", 0);
		return -1;
	}

	#
	# if we don't change the working dir, stuff like descrpath will not
	# contain /usr/ports/...etc.  It will look more like this:
	#     /usr/home/dan/walkports/
	# That's because DESCR is defined as .{CURDIR}/etc more or less
	#
	chdir "$MakefileDirectory";

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
	$makecommand = "make -V PORTNAME -V PKGNAME -V DESCR -V CATEGORIES -V PORTVERSION -V PORTREVISION " .
		" -V COMMENT -V COMMENTFILE -V MAINTAINER -V EXTRACT_SUFX " .
		" -V BUILD_DEPENDS -V RUN_DEPENDS -V LIB_DEPENDS -V FORBIDDEN -V BROKEN -V DEPRECATED -V IGNORE ".
		" -V MASTERPORT -V LATEST_LINK -V NO_LATEST_LINK -V NO_PACKAGE -V PKGNAMEPREFIX -V PKGNAMESUFFIX -V PORTEPOCH " .
		" -V RESTRICTED -V NO_CDROM -V EXPIRATION_DATE -V IS_INTERACTIVE " . 
		" -V ONLY_FOR_ARCHS -V NOT_FOR_ARCHS -f $Makefile " .
		" DISTDIR=$FreshPorts::Constants::DISTDIR " .
		" PORTSDIR=$FreshPorts::Config::path_to_ports LOCALBASE=/nonexistentlocal X11BASE=/nonexistentx 2>$TmpFile";

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
		print "trying to get master sites\n";
		my $mastersitescommand = "make master-sites-all -f $Makefile PORTSDIR=$FreshPorts::Config::path_to_ports " . 
		                         "LOCALBASE=/nonexistentlocal X11BASE=/nonexistentx";
		print "'$mastersitescommand'\n";
		$mastersites = `$mastersitescommand`;
		# save this for later reference
		$result = $?;

		chomp($mastersites);	# remove that trailing whitespace.

		# we'll need this for error reporting
		if ($result != 0) {
			# save the results for error reporting
			FreshPorts::CommitterOptIn::RecordErrorDetails("$this->{category}/$this->{name}", "\n\n" . "This command (FreshPorts code 2):\n\n$makecommand\n\nproduced this error:\n\n$mastersites");
			$ErrorMessage = $mastersites;
		}
	}

	print "\$result='$result'\n";
	print "\$mastersites='$mastersites'\n";

	# remove previously created directory
	if ($FreshPorts::Config::mkdir_pkg) {
		rmdir "pkg";
	}

	#
	# we need to check this return value.  if it fails, we need to know
	#

	if ($result == 0) {

		(my $portname, my $packagename, my $descrpath, my $categories, my $portversion, my $portrevision, my $shortdescription,
		 my $CommentFile, my $maintainer, my $extractsuffix, my $builddepends,
		 my $rundepends, my $libdepends, my $forbidden, my $broken, my $deprecated, my $ignore,
		 my $master_port, my $latest_link, my $no_latest_link, my $no_package, my $pkgnameprefix, my $pkgnamesuffix, my $portepoch,
		 my $restricted, my $no_cdrom, my $expiration_date, 
		 my $is_interactive, my $only_for_archs, my $not_for_archs) = split(/\n/s, $MakeResults);

		my $package_name = $pkgnameprefix . $portname . $pkgnamesuffix;

		$builddepends	= freshports_ConvertPortPathToStandardLocation(FreshPorts::Utilities::trim_multiple_to_single(FreshPorts::Utilities::trim($builddepends)));
		$rundepends		= freshports_ConvertPortPathToStandardLocation(FreshPorts::Utilities::trim_multiple_to_single(FreshPorts::Utilities::trim($rundepends)));
		$libdepends		= freshports_ConvertPortPathToStandardLocation(FreshPorts::Utilities::trim_multiple_to_single(FreshPorts::Utilities::trim($libdepends)));
		
		$master_port =~ s|$FreshPorts::Config::path_to_ports/||;

		print " portname     = '$this->{name}'\n";
		print " packagename  = '$portname'\n";
		print " category     = '$this->{category}'\n";
		print " packagename  = '$packagename'\n";
		print " descrpath    = '$descrpath'\n";
		print " categories   = '$categories'\n";
		print " portversion  = '$portversion'\n";
		print " portrevision = '$portrevision'\n";
		print " comment      = '$shortdescription'\n";
		print " CommentFile  = '$CommentFile'\n";
		print " maintainer   = '$maintainer'\n";
		print " extractsuffix= '$extractsuffix'\n";
		print " mastersites  = '$mastersites'\n";
		print " builddepends = '$builddepends'\n";
		print " rundepends   = '$rundepends'\n";
		print " libdepends   = '$libdepends'\n";

		# eliminate multiple // : PR 174
		# to compensate for bug in File::PathConvert::realpath (which is no longer used; Cwd is used instead)
		$descrpath   =~ s|//|/|g;

		my $RealDescrPath	= Cwd::abs_path($descrpath);

		if (!defined($shortdescription)) {
			die("OK, good, we have no short description");
		}

		# if it's defined, and it exists....
		my $longdescription = '';
		my $homepage        = '';
		if (defined($RealDescrPath) && -f $RealDescrPath) {
			($longdescription, $homepage) = _GetDescrAndHomePage($RealDescrPath);
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
		$this->{categories}			= $categories;
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

	if (!IsValidDate($this->{expiration_date})) {
		$ErrorMsg .= " EXPIRATION_DATE contains '" . $this->{expiration_date} . "', which is not a valid date."
	}

	if ($ErrorMsg ne '') {
		FreshPorts::CommitterOptIn::RecordErrorDetails(
			"$this->{category}/$this->{name}",
			$ErrorMsg);
		$result = -1;		
	}

	return $result;
}

sub _FetchFilesNeedingRefresh {
	# returns 0 for success, 1 for failure
	# a return of -1 indicates an error.

	my $this	= shift;
	my $result	= 1;

	my $TmpFile = FreshPorts::Utilities::TmpFileName("$this->{category}.$this->{name}.make-error");

	print "into _FetchFilesNeedingRefresh ------------\n";

	# this is where we fetch the files to disk
	my $DESTDIR	= "$FreshPorts::Config::path_to_ports/$this->{category}/$this->{name}";

	#
	# this is the location in the repository where our main files reside.
	# in the case of a slave port, it's where the slave Makefile will be.
	# it is not necessarily where the pkg-descr and pkg-comment will reside.
	#
	my $SRCDIR	= "$FreshPorts::Config::ports_prefix/$this->{category}/$this->{name}";

	my $FILE	= $FreshPorts::Constants::FILE_MAKEFILE;

	print "\$DESTDIR = $DESTDIR\n";
	print "\$SRCDIR  = $SRCDIR\n";
	print "\$FILE    = $FILE\n";

	if (FreshPorts::Utilities::FetchFile($DESTDIR, $SRCDIR, $FILE, $FreshPorts::Constants::HEAD)) {
		#
		# now that we have the Makefile for this port, let's figure out the full name
		# of the pkg-descr and pkg-comment files.  They may belong to another port.
 		#

		if (!LooksLikeAMakefile("$DESTDIR/$FILE")) {
			FreshPorts::Utilities::ReportError('warning', "$DESTDIR/$FILE does not look like a makefile", 0);
			#
			# lets try returning 1 instead of -1, the fetch may have failed... and given us HTML or rather
			# more precisely, non-ASCII
			#
			return 1;
		}

		print "now doing a chdir to $DESTDIR\n";
		if (!chdir("$DESTDIR")) {
			my $error = $!;
			FreshPorts::Utilities::ReportError('warning', "error doing a chdir $DESTDIR $error\n", 1);
		}


		#
		# create this directory to catch errors
		# such as the pre-everything having only one ':'
		#
		if ($FreshPorts::Config::mkdir_pkg) {
			mkdir "pkg",0;
		}

		my $makecommand = "make -V DESCR -f $DESTDIR/$FILE PORTSDIR=$FreshPorts::Config::path_to_ports " .
		                  "LOCALBASE=/nonexistentlocal X11BASE=/nonexistentx 2>$TmpFile";

		print "makecommand = $makecommand\n";
		my $MakeResults = `$makecommand`;
		my $Result = $?;

		if (-s $TmpFile > 0) {
			my $Errors = `cat $TmpFile`;
			FreshPorts::Utilities::ReportErrorEmail('warning', "error executing make command for $this->{category}/$this->{name} for database $FreshPorts::Config::dbname\n: '$makecommand' ->" . $Errors, 1, 0);
		}
		# remove the error collection file
		unlink($TmpFile);


		# remove previously created directory
		rmdir "pkg";

		#
		# we need to check this return value.  if it fails, we need to know
		#

		if ($Result == 0) {
			(my $DESCR) = split(/\n/s, $MakeResults);

			#
			# If the port contains something like this:
			# PORTVERSION=    ${MAKE} -V PORTVERSION -f ${MAINDIR}/${MAKEFILE}
			# it will fail when using the -f option.  The error will be of this form:
			#   make: cannot open /usr/home/dan/ports/misc/cheatah/../sword//usr/home/dan/ports/misc/cheatah/Makefile.
			# which is what $DESCR will contain.
			# which means the call to File::PathConvert::realpath below will fail
			# BUT now we use Cwd, not File::PathConvert
			#
			# The solution is at http://www.freebsd.org/cgi/cvsweb.cgi/ports/www/mozilla-embedded/Makefile.diff?r1=1.15&r2=1.16&f=h
			# In summary, like this:
			#	PORTVERSION=   ${MAKE} -V PORTVERSION -f ${MAINDIR}/${MKFILE}
			#	MKFILE!=     /usr/bin/basename ${MAKEFILE}
			#



			print "raw data DESCR = '$DESCR'\n";

			#
			# some ports (e.g. korean/netscape47-communicator) use
			# ../ in their path names.  We must remove that in order
			# to find out if have to retrieve a file in our path
			#

			# eliminate multiple // : PR 174
			# to compensate for bug in File::PathConvert::realpath
			# but now we use Cwd.
			$DESCR =~ s|//|/|g;
			
			print "raw data DESCR = '$DESCR'\n";

			

			#
			# Recent observation (2003.02.10) shows that COMMENTFILE
			# returns the realpath.  If empty, then COMMENTFILE is 
			# not used and COMMENT returns the actual comment.
			#
			$DESCR = Cwd::abs_path($DESCR);
			print "raw data DESCR = '$DESCR'\n";


			if (defined($DESCR)) {
				print "converted data DESCR       = '$DESCR'\n";

				#
				# now fetch the file.  Since we obtained
				# these values from the Makefile, we don't have to
				# specify any directory prefix.  The Makefile did that.
				#

				my $directory	= File::Basename::dirname ($DESCR);
				my $FILE		= File::Basename::basename($DESCR);
				my $DESTDIR		= $directory;
				$SRCDIR			= File::Basename::dirname(RemovePortsPrefix($DESCR));

				print "fetching \$DESTDIR = [$DESTDIR], \$SRCDIR = [$SRCDIR], \$FILE = [$FILE]\n";

				if (FreshPorts::Utilities::FetchFile($DESTDIR, $SRCDIR, $FILE, $FreshPorts::Constants::HEAD)) {
					$result = 0;
				}
			} else {
				print "That make failed to return values for '-V DESCR.  I suspect an embedded make has failed.\n\n";

				FreshPorts::Utilities::ReportError('warning', "That make failed to return values for '-V DESCR'.  I suspect an embedded make has failed. $this->{category}/$this->{name}", 0);
				FreshPorts::CommitterOptIn::RecordErrorDetails("$this->{category}/$this->{name}", "\n\nThat make failed to return values for '-V DESCR'.  I suspect an embedded make has failed.\n\n");
				$result = -1;
			}
			

		} else {
			my $error = $?;
			print "That make failed:\n\n'$MakeResults' - '$error'\n\n";
			FreshPorts::Utilities::ReportError('warning', "error executing make command for $this->{category}/$this->{name}: Error Code = " . ($error >> 8), 0);
			FreshPorts::CommitterOptIn::RecordErrorDetails("$this->{category}/$this->{name}", "\n\n" . $MakeResults. "\n\n");
			$result = -1;
		}
	} else {
		FreshPorts::Utilities::ReportError('warning', "error fetching Makefile", 0);
	}

	print "exit _FetchFilesNeedingRefresh ------------\n";

	return $result;
}


# =================================
sub _GetDescrAndHomePage($) {

	my $file = shift;
	my $url;
	my $DESCR;

	open (F,$file) || FreshPorts::Utilities::ReportError('warning', "couldn't open $file: $!", 1);
	$DESCR = "";
	
	while(<F>){
		$DESCR .= $_;
		if(/WWW:(.*)/) {

#			print "found a home page of $url\n";

			$url = $1;
			$url =~  s/^\s+//g;
		}
	}

	close F;

	my @result = ($DESCR, $url);

	return @result;
}


sub RefreshFromFiles($;$) {
#
# refresh this port based on the make files associated with it and the value of needs_refresh
# returns 0 for success, 1 for failure
#
	my $this			= shift;
	my $needs_refresh	= shift;
	my $fetch_files		= shift;

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
			$result = $this->_FetchFilesNeedingRefresh();
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
		$error = $this->_ExtractValuesFromMakefile();
	}

	if (!$FetchAttempts || $error) {
		$result = 1;
	}

	return $result;
}

sub GetNeedsRefreshForNewPort {
	my $this = shift;

	my $needs_refresh	= 0;
	my $result			= -1;
	my $fetch_code;

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


sub RemovePortsPrefix($) {
	#
	# remove the ports prefix from the pathname
	# this gives us the path into the CVS repo
	# example:
	# input:  /home/dan/ports/devel/hypersrc/Makefile
	# output: ports/devel/hypersrc/Makefile
	#
	# assumes $FreshPorts::Config::path_to_tree is correctly set
	#

	#
	# convert to the real path.  e.g. /home/dan to /usr/home/dan
	#

	my $SuffixPath = shift;
	print "into RemovePortsPrefix => $SuffixPath\n";

	# eliminate multiple // : PR 174
	# to compensate for bug in File::PathConvert::realpath
	# but now we use Cwd.
	$SuffixPath =~ s|//|/|g;

	$SuffixPath = Cwd::abs_path($SuffixPath);

	# add a trailing slash to the real path!
	my $Prefix = $FreshPorts::Config::path_to_ports;
	$Prefix =~ s|//|/|g;
	$Prefix = Cwd::abs_path($Prefix) . "/";

	print "\$Prefix => $Prefix\n";

	#print "RemovePortsPrefix \$Prefix = $Prefix\n";

	# use regex to remove the prefix
	$SuffixPath =~ s/$Prefix//;
	$SuffixPath = $FreshPorts::Config::ports_prefix . '/' . $SuffixPath;

	print "exit RemovePortsPrefix => $SuffixPath\n";

	return $SuffixPath;
}

sub LooksLikeAMakefile($) {
	my $Makefile = shift;
	my $Result   = 1;
	
	my $Command = "file -b $Makefile";

	my $filetype = `$Command`;
	chomp($filetype);

	print "\n$Command gives:\n";
	print "$filetype\n\n";

	# look for HTML at the start of the file output
	my $index = index($filetype, 'HTML', 0);
	print "index result " . $index . "\n";

	if ($index == 0) {
		print "nope, that's HTML, not a Makefile as far as I'm concerned....\n";
		$Result = 0;
	}

	return $Result;
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

sub _NULLIfEmpty {
	my $this   = shift;
	my $value  = shift;

	my $result = undef;

	if (!defined($value) || $value eq '') {
		$result = 'NULL';
	} else {
		$result = $this->{dbh}->quote($value);
	}

	return $result;

}


sub IsValidDate {
	return 1;
}


FreshPorts::Utilities::InitSyslog();

1;
