#!/usr/bin/perl
#
# $Id: ports_categories.pm,v 1.2 2006-12-17 12:04:01 dan Exp $
#
# Copyright (c) 2001-2003 DVL Software
#

package FreshPorts::Ports_generate_plist;

use strict;
use utilities;

# =================================

sub _initialize {
}

# =================================

sub new {
	my $this	= {};
	my $class	= shift;
	$this->{dbh}	= shift;
	bless $this;
	$this->_initialize();
	return $this
}

sub save {
	my $this = shift;

	my $dbh = $this->{dbh}; # just a short cut...
	$this->{port_id}        = shift;
	$this->{generate_plist} = shift;
	my $sth;
	my @sql;
	my $sql;
	my @row;
	
	print "generate_plist is:\n###\n" . $this->{generate_plist} . "\n###\n";
	$sql = 'DELETE FROM generate_plist WHERE port_id = ' . $this->{port_id} . ';';
	print "sql is $sql\n";
	$sth = $this->{dbh}->prepare($sql);
	if (!$sth->execute) {
		FreshPorts::Utilities::ReportError('warning', "Could not execute SQL $sql ... maybe invalid? ". $dbh->errstr, 1);
	}

	print "into ports_generate_plist.pm::save()\n";
	
	if ($this->{generate_plist} eq '') {
	  print "nothing in generate_plist to save; leaving\n";
	  return;
	}

	$sql = 'INSERT INTO generate_plist (port_id, installed_file) VALUES ';

	my (@lines) = split("\n", $this->{generate_plist});

	for (@lines) {
	  if (!$_) {
	    print "ignoring empty string\n";
	  } else {
	    print "pushing '$_'\n";
	    push @sql, "( $this->{port_id}, " . $this->{dbh}->quote($_) . ')';
	  }
	}

    $sql .= join(',', @sql) . ';';

	print "sql is $sql\n";
	$sth = $this->{dbh}->prepare($sql);
	if (!$sth->execute) {
		FreshPorts::Utilities::ReportError('warning', "Could not execute SQL $sql ... maybe invalid? ". $dbh->errstr, 1);
	}
}

1;
