#!/usr/bin/perl
#
# $Id: category.pm,v 1.11 2012-12-30 13:04:23 dan Exp $
#
# Copyright (c) 2001-2003 DVL Software
#

package FreshPorts::Category;
require Exporter;
require	config;
require utilities;

use strict;
use config;

# =================================

sub _initialize {
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

sub _populate {
	my $this = shift;
	my $row  = shift;

	$this->{id} 			= $row->{id};
	$this->{is_primary}		= $row->{is_primary};
	$this->{element_id}		= $row->{element_id};
	$this->{name}			= $row->{name};
	$this->{description}	= $row->{description};
}


sub save {
	my $this = shift;

#	print "into FreshPorts::Category::save\n";

	#
	# if id is supplied, we are updating. otherwise we are inserting.
	# if element_id is supplied, it will be used.  Otherwise, it will
	# be derived from name based on /ports/<name>.
	# A new element will be created if necessary.
	#
	# For new categories:
	# description will be obtained from the contents of
	# /ports/<name>/pkg/COMMENT
	# 

	my $dbh = $this->{dbh}; # just a short cut...
	my $sth;
	my $sql;
	my @row;

	# get the name if not supplied
	if (!$this->{name}) {
		FreshPorts::Utilities::ReportError('warning', "name not supplied", 1);
	}

	if (!defined($this->{is_primary})) {
		FreshPorts::Utilities::ReportError('warning', "is_primary not supplied", 1);
	}

	if (!$this->{description}) {
		$this->{description} = _description_fetch("$this->{name}");
	}

	my $elementid;
	if (defined($this->{element_id})) {
		$elementid = $this->{element_id};
	} else {
		$elementid = 'NULL';
	}

	if ($this->{id}) {
		# we are updating
		$sql = "update categories  
				set 
				is_primary = " . $dbh->quote($this->{is_primary}) . ", 
				element_id = " . $elementid . ",
				name      = " . $dbh->quote($this->{name}) . ", 
				description = " . $dbh->quote($this->{description}) . " 
				 where id = $this->{id}";
		$sth = $this->{dbh}->prepare($sql);
		$sth->execute ||
			FreshPorts::Utilities::ReportError('warning', "Could not execute SQL $sql ... maybe invalid?", 1);
	} else {
		# we are inserting
		$sql = "select CreateCategory(" . $dbh->quote($this->{name}) . ", \
				" . $dbh->quote($this->{description}) . ", \
				" . $dbh->quote($this->{is_primary}) . ")";

#		print "sql is $sql\n";

		$sth = $this->{dbh}->prepare($sql);
		$sth->execute ||
			FreshPorts::Utilities::ReportError('warning', "Could not execute SQL $sql ... maybe invalid?", 1);

		@row = $sth->fetchrow_array();

		$sth->finish();

		$this->{id} = $row[0];

	}

	# after saving, return the ID
	return $this->{id};
}

sub FetchByID {
	my $this	= shift;

	my $dbh;
	my $sql;
	my $sth;
	my $row;

	$dbh = $this->{dbh};

	$sql = "select * from categories where id = $this->{id}";
	print "sql = '$sql'\n";

	$sth = $dbh->prepare($sql);
	if ( !defined $sth ) {
		FreshPorts::Utilities::ReportError('warning', "Could not prepare SQL $sql" . pg_lasterror(), 1);
	}
	if (!$sth->execute) {
		FreshPorts::Utilities::ReportError('warning', "Could not execute SQL $sql" . pg_lasterror(), 1);
	}

	$row = $sth->fetchrow_hashref();

	$sth->finish();

	$this->_populate($row);

	return $this->{id};
}

sub FetchByName {
	# obtain the element based on the pathname supplied
	my $this	= shift;

	my $dbh;
	my $sql;
	my $sth;
	my $row;
	my $tmp;

	$dbh = $this->{dbh};
	if (!$dbh) {
		FreshPorts::Utilities::ReportError('warning', "no database handle!", 1);
	}

	$tmp = $dbh->quote($this->{name});
	$sql = "select * from categories where name = $tmp";
	print 'sql = "' . $sql . '"' . "\n";

	$sth = $dbh->prepare($sql);
	if (!$sth->execute) {
		FreshPorts::Utilities::ReportError('warning', "Could not execute SQL $sql", 1);
	}

	$row = $sth->fetchrow_hashref();

	$sth->finish();
	if ($row) {
		$this->_populate($row);
	} else {
		print "NOT FOUND\n";
	}

	return $this->{id};
}

# =================================

sub _description_read {
	my $category	= shift;

	my $description = '';

	my $MakefileDirectory = "$FreshPorts::Config::path_to_ports/$category";
	my $TmpFile = FreshPorts::Utilities::TmpFileName("$category.make-error");

	my $ErrorMessage = '';	# stores the result of the latest make command
							# in case we need it for error reporting
	my $OtherErrors  = '';	# gets the results of the TmpFile used to collect errors.

	chdir "$MakefileDirectory";

#	my $makecommand = "make -V COMMENT " .
#	               "DISTDIR=$FreshPorts::Constants::DISTDIR " .
#	               "PORTSDIR=$FreshPorts::Config::path_to_ports LOCALBASE=/nonexistentlocal 2>$TmpFile";
	
	my $makecommand = "/usr/local/bin/sudo /usr/sbin/chroot -u $FreshPorts::Config::JailUser $FreshPorts::Config::JailBaseDir $FreshPorts::Config::JailCategoryDescrptionScript $category 2>$TmpFile";
	print "makecommand = $makecommand\n";

	my $MakeResults = `$makecommand`;
	# save this for later reference
	my $result = $?;

	print 'Result = ' . $result . "\n";

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
		FreshPorts::CommitterOptIn::RecordErrorDetails($category, $ErrorMessage);
		$result = -1;
	}

	# remove that error collection file
	`rm $TmpFile`;

	if ($result == 0) {
		($description) = split(/\n/s, $MakeResults);
	}

	return $description;

}

sub _description_fetch {
	my $category	= shift;

	my $DESTDIR	= "$FreshPorts::Config::path_to_ports/$category";
	my $SRCDIR	= "ports/$category";
	my $FILE	= "Makefile";

	my $description;

#	print "FreshPorts::Config::scriptpath=$FreshPorts::Config::scriptpath\n";
	print "DESTDIR=$DESTDIR\n";
	print "SRCDIR =$SRCDIR\n";
	print "FILE   =$FILE\n";

	if (FreshPorts::Utilities::FetchFile($DESTDIR, $SRCDIR, $FILE, $FreshPorts::Constants::HEAD)) {
		$description = _description_read("$category");

	} else {
		FreshPorts::Utilities::ReportError('warning', "Could not fetch file for '$DESTDIR' '$SRCDIR' '$FILE'.  Error code = " . ($? >> 8), 0);
		$description = 'No description supplied (pkg/COMMENT not found)';
	}

	# get rid of the trailing CR/LF.
	chomp $description;

	return $description;
}

sub FetchAll {
	#
	# return a hash containing one entry for each category
	#
	my $this = shift;
	
	my $sql;
	my $sth;
	my $row;
	my %Categories;
	my $category;
	my $dbh = $this->{dbh};

	$sql = "select * from categories order by name";
	print "sql = '$sql'\n";

	$sth = $dbh->prepare($sql);
	if ( !defined $sth ) {
   	FreshPorts::Utilities::ReportError('warning', "Could not prepare SQL $sql" . pg_lasterror(), 1);
	}

	if (!$sth->execute) {
   	FreshPorts::Utilities::ReportError('warning', "Could not execute SQL $sql" . pg_lasterror(), 1);
	}

	while ($row = $sth->fetchrow_hashref()) {
		$category = FreshPorts::Category->new($dbh);
   	print "found $row->{id} = $row->{name}\n";

		$category->{id} = $row->{id};
		$category->FetchByID();
	   $Categories{$row->{name}} = $category;
	}

	return %Categories;
}

sub RefreshDescription {
	my $this = shift;

	$this->{description} = FreshPorts::Category::_description_read($this->{name});
}

1;

