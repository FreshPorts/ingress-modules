#!/usr/local/bin/perl
#
# $Id: element.pm,v 1.13 2012-09-25 18:11:23 dan Exp $
#
# Copyright (c) 2001-2003 DVL Software
#

package FreshPorts::Element;

use strict;
use File::Basename;
use FreshPorts::utilities;

$FreshPorts::Element::Active	= 'A';
$FreshPorts::Element::Deleted	= 'D';

sub new {
	my $this			= {};
	my $class		= shift;
	$this->{dbh}	= shift;
	bless $this;
	$this->_initialize();
	return $this
}

sub _initialize {
}

sub save {
	my $this = shift;

	#
	# if id is supplied, we are updating. otherwise we are inserting.
	# if parent_id is supplied, it will be used.  Otherwise, it will
	# be derived from pathname.  if parent_id is set, it is assumed
	# that pathname is correct.
	# if name is not supplied, it will be derived from pathname.
	# 

	my $dbh = $this->{dbh}; # just a short cut...
	my $sth;
	my $sql;
	my @row;

	# get the name if not supplied
	if (!$this->{name}) {
		if (!$this->{pathname}) {
			FreshPorts::Utilities::ReportError('warning', "neither name nor pathname supplied", 1);
		}
		$this->{name} = File::Basename::basename($this->{pathname});
	}

	if (!$this->{status}) {
		$this->{status} = $FreshPorts::Element::Active;
	}

	# if we don't have the parent id, derive it from the pathname
	if (!$this->{parent_id}) {
		#
		# our parent's name is the basename of our pathname
		# i.e. our path name - our name.
		#
		if (!$this->{pathname}) {
			FreshPorts::Utilities::ReportError('warning', "neither parent_id nor pathname supplied", 1);
		}

		#
		# my parent's name is my name less the last directory/file.
		#
		my $parent_name = File::Basename::dirname($this->{pathname});

		#
		# fetch the element with that name
		#
		my $parent = FreshPorts::Element->new($dbh);
		$parent->{pathname} = $parent_name;
		$this->{parent_id}  = $parent->FetchByName();
	}

	if ($this->{id}) {
		# we are updating

		my $parentID;

		if ($this->{parent_id} eq '')
		{
			$parentID = 'null';
		}
		else
		{
			$parentID = $this->{parent_id}
		}

		$sql = "
update element  
   set name                = " . $dbh->quote($this->{name}) . ", 
       parent_id           = $parentID,
       directory_file_flag = " . $dbh->quote($this->{directory_file_flag}) . ", 
       status              = " . $dbh->quote($this->{status}) . " 
 where id                  = $this->{id}";

		$sth = $this->{dbh}->prepare($sql);
		$sth->execute ||
			FreshPorts::Utilities::ReportError('warning', "Could not execute SQL $sql ... maybe invalid?", 1);
	} else {
		# we are inserting
		$sql = "select Element_Add(" . $dbh->quote($this->{pathname}) . ", \
									'$this->{directory_file_flag}')";

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

sub update_status {
	my $this = shift;

	#
	# if id is supplied, we are updating. otherwise we are inserting.
	# if parent_id is supplied, it will be used.  Otherwise, it will
	# be derived from pathname.  if parent_id is set, it is assumed
	# that pathname is correct.
	# if name is not supplied, it will be derived from pathname.
	# 

	my $dbh = $this->{dbh}; # just a short cut...
	my $sth;
	my $sql;
	my @row;

	if ($this->{id}) {
		# we are updating

		$sql = "
update element  
   set status = " . $dbh->quote($this->{status}) . " 
 where id     = $this->{id}";

		$sth = $this->{dbh}->prepare($sql);
		$sth->execute ||
			FreshPorts::Utilities::ReportError('warning', "Could not execute SQL $sql ... maybe invalid?", 1);
	}

	# after saving, return the ID
	return $this->{id};
}


sub FetchByID {
	my $this	= shift;

	my $dbh		= $this->{dbh};

	my $sql = "select *, element_pathname(id) as pathname from element where id = $this->{id}";
#	print "sql = '$sql'\n";

	my $sth = $dbh->prepare($sql);
	if (!$sth->execute) {
		FreshPorts::Utilities::ReportError('warning', "Could not execute SQL $sql ... maybe invalid?", 1);
	}

	my $row = $sth->fetchrow_hashref();

	$sth->finish();

	$this->{id}                  = $row->{id};
	$this->{name}                = $row->{name};
	$this->{parent_id}           = $row->{parent_id};
	$this->{directory_file_flag} = $row->{directory_file_flag};
	$this->{status}              = $row->{status};
	$this->{pathname}            = $row->{pathname};

	return $this->{id};
}

sub FetchByName {
	# obtain the element based on the pathname supplied
	my $this	= shift;

	my $dbh		= $this->{dbh};
	if (!$dbh) {
		FreshPorts::Utilities::ReportError('warning', " no database handle!", 1);
	}

	my ($sql, $sth, @row);

	my $tmp = $dbh->quote("things");
	$sql = "select Pathname_ID(" . $dbh->quote($this->{pathname}) . ")";
	print "sql = '$sql'\n";

	$sth = $dbh->prepare($sql);
	if (!$sth->execute) {
		FreshPorts::Utilities::ReportError('warning', "Could not execute SQL $sql ... maybe invalid?", 1);
	}

	@row = $sth->fetchrow_array();

	print "Element::FetchByName - here is what that SQL returned\n";	
	foreach (@row) {
		if (defined($_)) {
			print "Element::FetchByName found: $_ \n";
		}
	}
	print "done....\n";	

	$sth->finish();
	$this->{id} = $row[0];
	
	# now that we have the ID for this name, let's fetch it...
	#
	if ($this->{id}) {
		print "I found this element id for that pathname: " . $this->{id} . "\n";
		return $this->FetchByID();
	} else {
		print "I found nothing for that pathname\n";
		return $this->{id};
	}
}

1;
