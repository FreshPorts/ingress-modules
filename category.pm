#!/usr/bin/perl
#
# $Id: category.pm,v 1.8.2.8 2003-05-16 01:13:59 dan Exp $
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
	my $this			= {};
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
	$this->{is_primary}	= $row->{is_primary};
	$this->{element_id}	= $row->{element_id};
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

	if ($this->{id}) {
		# we are updating
		$sql = "update categories  \
				set \
				is_primary = " . $dbh->quote($this->{is_primary}) . ", \
				element_id = $this->{element_id}, \
				name      = " . $dbh->quote($this->{name}) . ", \
				description = " . $dbh->quote($this->{description}) . " \
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
#	print "sql = '$sql'\n";

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
	print "sql = '$sql'\n";

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

sub _description_fetch {
	my $category	= shift;

	my $DESTDIR	= "$FreshPorts::Config::path_to_ports/$category/pkg";
	my $SRCDIR	= "ports/$category/pkg";
	my $FILE		= "COMMENT";

#	print "FreshPorts::Config::scriptpath=$FreshPorts::Config::scriptpath\n";
	print "DESTDIR=$DESTDIR\n";
	print "SRCDIR =$SRCDIR\n";
	print "FILE   =$FILE\n";

	`sh $FreshPorts::Config::scriptpath/fetch-cvs-file.sh $DESTDIR $SRCDIR $FILE $FreshPorts::Constants::HEAD`;
	if ($?) {
		FreshPorts::Utilities::ReportError('warning', "Could not fetch file for '$DESTDIR' '$SRCDIR' '$FILE'.  Error code = " . ($? >> 8), 1);
	}

	my $description = FreshPorts::Utilities::ReadFile("$DESTDIR/$FILE");

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

1;

