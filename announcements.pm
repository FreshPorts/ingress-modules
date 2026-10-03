#!/usr/local/bin/perl -w
#
# $Id: announcements.pm,v 1.3 2007-04-06 23:07:32 dan Exp $
#
# Copyright (c) 2001-2026 Dan Langille
#

package FreshPorts::Announcements;

use FreshPorts::utilities;

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

sub Get {
	my $this = shift;

	my $dbh = $this->{dbh}; # just a short cut...
	my $sth;
	my $sql;
	my $row;

	my $Announce = '';

	# we are inserting
	$sql = "select * from AnnouncementsGetPlain() as text";

#	print "sql is $sql\n";

	$sth = $this->{dbh}->prepare($sql);
	if (!$sth->execute) {
		FreshPorts::Utilities::ReportError('warning', "Could not execute SQL $sql ... maybe invalid? ". $dbh->errstr, 1);
	}

	while ($row = $sth->fetchrow_hashref()) {
		$Announce .= $row->{text} . "\n";
	}
	
	$sth->finish();

	return $Announce;
}

1;
