#!/usr/bin/perl
#
# $Id: port.pm,v 1.38.2.26 2003-07-17 12:45:38 dan Exp $
#
#
# Copyright (c) 2001-2003 DVL Software
#
package FreshPorts::Utilities;

package FreshPorts::Port;
require Exporter;
require config;
require element;
require utilities;
require committer_opt_in;

use File::PathConvert;
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

	$this->{portname}				= '';
	$this->{name}					= '';
	$this->{short_description}	= '';
	$this->{long_description}	= '';
	$this->{version}				= '';
	$this->{revision}				= '';
	$this->{maintainer}			= '';
	$this->{homepage}				= '';
	$this->{master_sites}		= '';
	$this->{extract_suffix}		= '';
	$this->{package_exists}		= '';
	$this->{depends_build}		= '';
	$this->{depends_run}			= '';
	$this->{forbidden}			= '';
	$this->{broken}				= '';
	$this->{categories}			= '';
	$this->{status}				= '';

print "$FreshPorts::Constants::commit_log_seq\n";
print "$FreshPorts::Constants::ports_seq\n";
print "$FreshPorts::Constants::commit_log_elements_seq\n";
}

sub _GetValuesFromRow {
	my $this = shift;
	my $row  = shift;

	$this->{id} 					= $row->{id};
	$this->{element_id}			= $row->{element_id};
	$this->{category_id}			= $row->{category_id};
	$this->{category}				= $row->{category};
	$this->{name}					= $row->{name};

	$this->{short_description}	= $row->{short_description};
	$this->{long_description}	= $row->{long_description};
	$this->{version}				= $row->{version};
	$this->{revision}				= $row->{revision};
	$this->{maintainer}			= $row->{maintainer};
	$this->{homepage}				= $row->{homepage};
	$this->{master_sites}		= $row->{master_sites};
	$this->{extract_suffix}		= $row->{extract_suffix};
	$this->{package_exists}		= $row->{package_exists};
	$this->{depends_build}		= $row->{depends_build};
	$this->{depends_run}			= $row->{depends_run};
	$this->{forbidden}			= $row->{forbidden};
	$this->{broken}				= $row->{broken};
	$this->{categories}			= $row->{categories};
	$this->{last_commit_id}		= $row->{last_commit_id};
	$this->{status}				= $row->{status};
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

	if ($this->{id}) {
		# we are updating

# correct this sql to update all fields...

		$sql = "
update ports  
   set short_description = " . $dbh->quote($this->{short_description})	. ", 
       long_description  = " . $dbh->quote($this->{long_description})	. ", 
       version           = " . $dbh->quote($this->{version})				. ", 
       revision          = " . $dbh->quote($this->{revision})				. ", 
       maintainer        = " . $dbh->quote($this->{maintainer})			. ", 
       homepage          = " . $dbh->quote($this->{homepage})				. ", 
       master_sites      = " . $dbh->quote($this->{master_sites})			. ", 
       extract_suffix    = " . $dbh->quote($this->{package_exists})		. ", 
       depends_build     = " . $dbh->quote($this->{depends_build})		. ", 
       depends_run       = " . $dbh->quote($this->{depends_run})			. ", 
       forbidden         = " . $dbh->quote($this->{forbidden})				. ", 
       broken            = " . $dbh->quote($this->{broken})					. ", 
       categories        = " . $dbh->quote($this->{categories});

		# we don't always have this value, so we don't change it....
		if (defined($this->{last_commit_id})) {
			$sql .= ", last_commit_id		= $this->{last_commit_id}";
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
          element.status
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
          element.status
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
	my $ErrorMessage;		# stores the result of the latest make command
								# in case we need it for error reporting

	my $TmpFile = FreshPorts::Utilities::TmpFileName("$this->{category}.$this->{name}.make-error");

	my $MakefileDirectory = "$FreshPorts::Config::path_to_ports/$this->{category}/$this->{name}";

	if (!LooksLikeAMakefile("$MakefileDirectory/$FreshPorts::Constants::FILE_MAKEFILE")) {
		FreshPorts::Utilities::ReportError('warning', "$MakefileDirectory/$FreshPorts::Constants::FILE_MAKEFILE does not look like a makefile", 0);
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
		" -V BUILD_DEPENDS -V RUN_DEPENDS -V FORBIDDEN -V BROKEN -f $MakefileDirectory/$FreshPorts::Constants::FILE_MAKEFILE " . 
		" PORTSDIR=$FreshPorts::Config::path_to_ports 2>$TmpFile";

	print "makecommand = $makecommand\n";

	my $MakeResults = `$makecommand`;
	# save this for later reference
	$result = $?;
	if (-s $TmpFile > 0) {
		my $Errors = `cat $TmpFile`;
		FreshPorts::Utilities::ReportErrorEmail('warning', "error executing make command for $this->{category}/$this->{name} for database $FreshPorts::Config::dbname\n: $makecommand => " . $Errors, 1, 0);
	}
	# remove that error collection file
	`rm $TmpFile`;

	if ($result != 0) {
		# save the results for error reporting
		$ErrorMessage = $MakeResults;
	}

	my $mastersites = '';
	if ($result == 0) {
		print "trying to get master sites\n";
		my $mastersitescommand = "make master-sites-all -f $MakefileDirectory/$FreshPorts::Constants::FILE_MAKEFILE PORTSDIR=$FreshPorts::Config::path_to_ports";
		print "'$mastersitescommand'\n";
		$mastersites = `$mastersitescommand`;
		# save this for later reference
		$result = $?;

		chomp($mastersites);	# remove that trailing whitespace.

		# we'll need this for error reporting
		if ($result != 0) {
			# save the results for error reporting
			$ErrorMessage = $mastersites;
		}
	}

	print "\$result='$result'\n";
	print "\$mastersites='$mastersites\n";

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
		 my $rundepends, my $forbidden, my $broken) = split(/\n/s, $MakeResults);

		$builddepends	= freshports_ConvertPortPathToStandardLocation(FreshPorts::Utilities::trim_multiple_to_single(FreshPorts::Utilities::trim($builddepends)));
		$rundepends		= freshports_ConvertPortPathToStandardLocation(FreshPorts::Utilities::trim_multiple_to_single(FreshPorts::Utilities::trim($rundepends)));

		print " portname     ='$this->{name}'\n";
		print " packagename  ='$portname'\n";
		print " category     ='$this->{category}'\n";
		print " packagename  ='$packagename'\n";
		print " descrpath    ='$descrpath'\n";
		print " categories   ='$categories'\n";
		print " portversion  ='$portversion'\n";
		print " portrevision ='$portrevision'\n";
		print " comment      ='$shortdescription'\n";
		print " CommentFile  = '$CommentFile'\n";
		print " maintainer   ='$maintainer'\n";
		print " extractsuffix='$extractsuffix'\n";
		print " mastersites  ='$mastersites'\n";
		print " builddepends ='$builddepends'\n";
		print " rundepends   ='$rundepends'\n";

		# eliminate multiple // : PR 174
		# to compensate for bug in File::PathConvert::realpath
		$descrpath   =~ s|//|/|g;

		my $RealDescrPath	= File::PathConvert::realpath($descrpath);

		if (!defined($shortdescription)) {
			die("OK, good, we have no short description");
		}

		# if it's defined, and it exists....
		my $longdescription = '';
		my $homepage        = '';
		if (defined($RealDescrPath) && -f $RealDescrPath) {
			($longdescription, $homepage) = _GetDescrAndHomePage($RealDescrPath);
		}

		my $packageexists = _PackageExists($packagename . ".tgz");

		chomp($longdescription); # get rid of the trailing whitespace.

		print "12 \$shortdescription= '$shortdescription'\n";
		print "13 \$longdescription ='$longdescription'\n";
		print "14 \$homepage='";
		if (defined($homepage)) {
			print "$homepage";
		}
		print "'\n";

		print "15 \$packageexists='$packageexists'\n";
		print "16 \$forbidden    ='$forbidden'\n";
		print "17 \$broken       ='$broken'\n";
		print "18 \$categories   ='$categories'\n";

		print "\n ---------------------------------------- \n";

		# convert a few values to zero if not defined.
		if (!defined($forbidden)) {
			$forbidden = '';
		}

		if (!defined($broken)) {
			$broken = '';
		}

		# put everything into the hash...

		$this->{portname}				= $portname;
		$this->{short_description}	= $shortdescription;
		$this->{long_description}	= $longdescription;
		$this->{version}				= $portversion;
		$this->{revision}				= $portrevision;
		$this->{maintainer}			= $maintainer;
		$this->{homepage}				= $homepage;
		$this->{master_sites}		= $mastersites;
		$this->{extract_suffix}		= $extractsuffix;
		$this->{package_exists}		= $packageexists;
		$this->{depends_build}		= $builddepends;
		$this->{depends_run}			= $rundepends;
		$this->{forbidden}			= $forbidden;
		$this->{broken}				= $broken;
		$this->{categories}			= $categories;

	} else {
		print "That make failed:\n\n$MakeResults\n\n";
		FreshPorts::Utilities::ReportError('warning', "error executing make command for $this->{category}/$this->{name}: " . $ErrorMessage, 0);
		FreshPorts::CommitterOptIn::RecordErrorDetails("\n\n" . $ErrorMessage . "\n\n");
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

		my $makecommand = "make -V DESCR -V -f $DESTDIR/$FILE PORTSDIR=$FreshPorts::Config::path_to_ports 2>$TmpFile";

		print "makecommand = $makecommand\n";
		my $MakeResults = `$makecommand`;
		my $Result = $?;

		if (-s $TmpFile > 0) {
			my $Errors = `cat $TmpFile`;
			FreshPorts::Utilities::ReportErrorEmail('warning', "error executing make command for $this->{category}/$this->{name} for database $FreshPorts::Config::dbname\n: '$makecommand' ->" . $Errors, 1, 0);
		}
		# remove the error collection file
		`rm $TmpFile`;


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
			#
			# The solution is at http://www.freebsd.org/cgi/cvsweb.cgi/ports/www/mozilla-embedded/Makefile.diff?r1=1.15&r2=1.16&f=h
			# In summary, like this:
			#	PORTVERSION=   ${MAKE} -V PORTVERSION -f ${MAINDIR}/${MKFILE}
			#	MKFILE!=     /usr/bin/basename ${MAKEFILE}
			#



			print "raw       data DESCR       = '$DESCR'\n";

			#
			# some ports (e.g. korean/netscape47-communicator) use
			# ../ in their path names.  We must remove that in order
			# to find out if have to retrieve a file in our path
			#

			# eliminate multiple // : PR 174
			# to compensate for bug in File::PathConvert::realpath
			$DESCR       =~ s|//|/|g;

			#
			# Recent observation (2003.02.10) shows that COMMENTFILE
			# returns the realpath.  If empty, then COMMENTFILE is 
			# not used and COMMENT returns the actual comment.
			#
			$DESCR = File::PathConvert::realpath($DESCR);

			if (defined($DESCR)) {
				print "converted data DESCR       = '$DESCR'\n";

				#
				# now fetch the file.  Since we obtained
				# these values from the Makefile, we don't have to
				# specify any directory prefix.  The Makefile did that.
				#

				my $directory	= File::Basename::dirname ($DESCR);
				my $FILE			= File::Basename::basename($DESCR);
				my $DESTDIR		= $directory;
				$SRCDIR			= File::Basename::dirname(RemovePortsPrefix($DESCR));

				print "fetching \$DESTDIR = [$DESTDIR], \$SRCDIR = [$SRCDIR], \$FILE = [$FILE]\n";

				if (FreshPorts::Utilities::FetchFile($DESTDIR, $SRCDIR, $FILE, $FreshPorts::Constants::HEAD)) {
					$result = 0;
				}
			} else {
				print "That make failed to return values for '-V DESCR.  I suspect an embedded make has failed.\n\n";

				FreshPorts::Utilities::ReportError('warning', "That make failed to return values for '-V DESCR'.  I suspect an embedded make has failed. $this->{category}/$this->{name}", 0);
				FreshPorts::CommitterOptIn::RecordErrorDetails("\n\nThat make failed to return values for '-V DESCR'.  I suspect an embedded make has failed.\n\n");
				$result = -1;
			}
			

		} else {
			print "That make failed:\n\n$MakeResults\n\n";
			my $error = $?;
			FreshPorts::Utilities::ReportError('warning', "error executing make command for $this->{category}/$this->{name}: Error Code = " . ($error >> 8), 0);
			FreshPorts::CommitterOptIn::RecordErrorDetails("\n\n" . $MakeResults. "\n\n");
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


# =================================
sub _PackageExists($) {
	# returns "Y" if the package exists, "N" otherwise.

	my $package = shift;
	my $exists  = "N";

	my $package_list = "$FreshPorts::Config::scriptpath/packages.exists";

	#
	# test for the file to grep
	#
	if (-f $package_list) {
		`grep $package $package_list`;

		if (!$?) {
			$exists = "Y";
		}
	}

	return $exists;
}

sub RefreshFromFiles($;$) {
#
# refresh this port based on the make files associated with it and the value of needs_refresh
# returns 0 for success, 1 for failure
#
	my $this				= shift;
	my $needs_refresh	= shift;
	my $fetch_files	= shift;

	if (!defined($needs_refresh)) {
		FreshPorts::Utilities::ReportError('warning', "needs_refresh has no value", 1);
	}

	my $result = 0;
	my $error;

	my $FetchAttempts = 5;

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
					sleep 10;
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
	$SuffixPath   =~ s|//|/|g;

	$SuffixPath = File::PathConvert::realpath($SuffixPath);

	# add a trailing slash to the real path!
	my $Prefix = $FreshPorts::Config::path_to_ports;
	$Prefix =~ s|//|/|g;
	$Prefix = File::PathConvert::realpath($Prefix) . "/";

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

	my $filetype = `file -b $Makefile`;
	chomp($filetype);

	print "$filetype\n";

	if (index($filetype, 'HTML', 0) != -1) {
		print "nope, that's HTML, not a Makefile as far as I'm concerned....\n";
		$Result = 0;
	}

	return $Result;
}


FreshPorts::Utilities::InitSyslog();

1;