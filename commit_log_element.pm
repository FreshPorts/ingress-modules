#!/usr/bin/perl
#
# $Id: commit_log_element.pm,v 1.4.2.3 2004-08-18 16:10:59 dan Exp $
#
# Copyright (c) 2001-2003 DVL Software
#


package FreshPorts::CommitLogElement;

use strict;
use utilities;

require constants;


sub new {
	my $this		= {};
	my $class		= shift;
	$this->{dbh}	= shift;
	bless $this;
	$this->_initialize();
	return $this
}

sub _initialize {
}

sub save {
	#
	# This function works only for inserts, not for updates
	#
	my $this = shift;

	my $dbh = $this->{dbh}; # just a short cut...
	my $sth;
	my $sql;
	my @row;

	print "commit_log_element::save..........\n";
	print "\$FreshPorts::Constants::commit_log_seq='$FreshPorts::Constants::commit_log_seq'\n";
	print "\$FreshPorts::Constants::ports_seq='$FreshPorts::Constants::ports_seq'\n";
	print "\$FreshPorts::Constants::commit_log_elements_seq='$FreshPorts::Constants::commit_log_elements_seq'\n";

	if (!$this->{id}) {
		print "getting id from '" . $FreshPorts::Constants::commit_log_elements_seq . "'\n";
		$this->{id} = FreshPorts::Database::GetNextValue($FreshPorts::Constants::commit_log_elements_seq, $dbh);
		# we are inserting
		$sql = "insert into commit_log_elements(id, commit_log_id, element_id, revision_name, change_type) values \
					($this->{id}, $this->{commit_log_id}, $this->{element_id}, " . $dbh->quote($this->{revision_name}) . ", " 
					 . $dbh->quote($this->{change_type}) . ")";

		print "sql is $sql\n";

		$sth = $this->{dbh}->prepare($sql);
		if (!$sth->execute) {
			FreshPorts::Utilities::ReportError('warning', "Could not execute SQL $sql ... maybe invalid? ". $dbh->errstr, 1);
		}
	} else {
		FreshPorts::Utilities::ReportError('warning', "FreshPorts::CommitLogElements::save works for updates only", 1);
	}
}

1;