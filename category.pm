#!/usr/local/bin/perl
#
# $Id: category.pm,v 1.12 2013-03-23 22:15:50 dan Exp $
#
# Copyright (c) 2001-2003 DVL Software
#

package FreshPorts::Category;

require Exporter;
require FreshPorts::config;
require FreshPorts::utilities;

use strict;
use FreshPorts::config;

# =================================

sub _initialize {
}

# =================================

sub new {
	my $this    = {};
	my $class   = shift;

	$this->{dbh} = shift;

	bless $this;
	$this->_initialize();
	return $this;
}

sub _populate {
	my $this = shift;
	my $row  = shift;

	$this->{id}          = $row->{id};
	$this->{is_primary}  = $row->{is_primary};
	$this->{element_id}  = $row->{element_id};
	$this->{name}        = $row->{name};
	$this->{description} = $row->{description};
}


sub save {
	my $this         = shift;
	my $CommitBranch = shift;

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
		$this->{description} = _description_fetch($CommitBranch, $this->{name});
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
	my $this = shift;

	my $dbh;
	my $sql;
	my $sth;
	my $row;

	$dbh = $this->{dbh};

	$sql = "select * from categories where id = $this->{id}";
	print "sql = '$sql'\n";

	$sth = $dbh->prepare($sql);
	if ( !defined $sth ) {
		FreshPorts::Utilities::ReportError('warning', "Could not prepare SQL $sql" . pg_last_error(), 1);
	}
	if (!$sth->execute) {
		FreshPorts::Utilities::ReportError('warning', "Could not execute SQL $sql" . pg_last_error(), 1);
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
	my $Repository   = shift;
	my $CommitBranch = shift;
	my $category     = shift;

	my $description = '';

	my $TmpFile = FreshPorts::Utilities::TmpFileName("$category.make-error");

	my $ErrorMessage = '';	# stores the result of the latest make command
	                        # in case we need it for error reporting
	my $OtherErrors  = '';	# gets the results of the TmpFile used to collect errors.

	# with subversion, FreshPorts held a different working copy of the repo for the quarterly branch
	# and another for head.	
	my $REPODIR_CHROOT = $FreshPorts::Config::PortsDir;

	my $makecommand = "/usr/local/bin/sudo /usr/sbin/jexec $FreshPorts::Config::JailName $FreshPorts::Config::JailCategoryDescrptionScript $REPODIR_CHROOT $category 2>$TmpFile";
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
	my $CommitBranch = shift;
	my $category     = shift;

	# not sure this used, especially so now that we're moving to git
	my $DESTDIR = "$FreshPorts::Config::PortsDir/$category";
	my $SRCDIR  = "ports/$category";
	my $FILE    = "Makefile";

	my $description;

#	print "FreshPorts::Config::ScriptDir=$FreshPorts::Config::ScriptDir\n";
	print "DESTDIR=$DESTDIR\n";
	print "SRCDIR =$SRCDIR\n";
	print "FILE   =$FILE\n";

	$description = _description_read($CommitBranch, $category);

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
   	FreshPorts::Utilities::ReportError('warning', "Could not prepare SQL $sql" . pg_last_error(), 1);
	}

	if (!$sth->execute) {
   	FreshPorts::Utilities::ReportError('warning', "Could not execute SQL $sql" . pg_last_error(), 1);
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

# XXX not sure this is used by anyone
sub RefreshDescription {
	my $this         = shift;
	my $Repository   = shift;
	my $CommitBranch = shift;

	$this->{description} = FreshPorts::Category::_description_read($Repository, $CommitBranch, $this->{name});
}

1;
