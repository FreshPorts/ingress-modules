#
# $Id: non_ports.pm,v 1.2 2006-12-17 12:04:01 dan Exp $
#
# Copyright (c) 2001-2003 DVL Software
#

package FreshPorts::NonPorts;

use strict;
use utilities;

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

sub RecordPortsTreeButNonPortCommits($;$;$) {
#
# This function will add an entry to the latest_commits_ports table
# for any commit which touches a file in the ports tree.
# It should not be called for any commit which touches a port.
# Such commits are handled by a trigger on the commit_log_ports table.
#
	my $commit_log_id	= shift;
	my $Files			= shift;
	my $dbh				= shift;

	my $PortTreeCommit = 0;
	print "into RecordPortsTreeButNonPortCommits\n";

	my $value;
	foreach $value (@{$Files}) {
		my ($action, $filename, $revision, $commit_log_element_id) = @$value;
		print " processing $filename\n";
		if ($filename =~ m|^/?ports/|) {
			$PortTreeCommit = 1;
			last;
		}
	}

	if ($PortTreeCommit) {
		print " yes, that was a port tree commit\n";
		_LatestCommitsPortsInsert($commit_log_id, $dbh);
	} else {
		print " nothing in this commit touched the ports tree\n";
	}

	print "done RecordPortsTreeButNonPortCommits\n";

	return 1;
}

sub _LatestCommitsPortsInsert($;$) {
	my $CommitLogID = shift;
	my $dbh	        = shift;

	my $sth;
	my $sql;

	$sql = "select commit_log_ports_insert($CommitLogID)";
	$sth = $dbh->prepare($sql);
	$sth->execute ||
			FreshPorts::Utilities::ReportError('warning', "Could not execute SQL $sql ... maybe invalid? " . $dbh->errstr, 1);
}

1;
