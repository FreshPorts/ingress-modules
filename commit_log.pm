#!/usr/local/bin/perl
#
# $Id: commit_log.pm,v 1.7 2012-09-25 18:11:23 dan Exp $
#
# Copyright (c) 2001-2003 DVL Software
#

package FreshPorts::Commit_Log;

use strict;
use FreshPorts::utilities;
use File::Basename;

sub new {
	my $this     = {};
	my $class    = shift;
	$this->{dbh} = shift;

	bless $this;

	$this->_initialize();

	return $this
}

sub _initialize {
	my $this = shift;
	my $row  = shift;

	$this->{encoding_losses} = 0;

	# by default, we use subversion.
	# we set this, because we are moving to git.	
	$this->{repository} = $FreshPorts::Constants::Subversion;
}

sub setRepo {
	my $this  = shift;
	my $repo  = shift;

	defined($FreshPorts::Constants::Repositories{$repo}) || die('no known repository' . $repo);
	
	$this->{repository} = $repo;
}

sub _GetValuesFromRow {
	my $this = shift;
	my $row  = shift;

	$this->{id}              = $row->{id};
	$this->{message_id}      = $row->{message_id};
	$this->{message_date}    = $row->{message_date};
	$this->{message_subject} = $row->{message_subject};
	$this->{date_added}      = $row->{date_added};
	$this->{commit_date}     = $row->{commit_date};
	$this->{committer}       = $row->{committer};
	$this->{description}     = $row->{description};
	$this->{encoding_losses} = $row->{encoding_losses};
	$this->{system_id}       = $row->{system_id};
	$this->{revision}        = $row->{revision};
	$this->{repo}            = $row->{repo};
}

sub save {
	my $this = shift;
	my $dbh = $this->{dbh}; # just a short cut...

	my $sth;
	my $sql;
	my @row;
	
	print "\$this->{repo}       = '$this->{repo}'\n";
	print "\$this->{repository} = '$this->{repository}'\n";

	$this->{id} = FreshPorts::Database::GetNextValue($FreshPorts::Constants::commit_log_seq, $dbh);
	
	# repo is one of ports, doc, src, etc. It relates to the repo.name column
	# repository is one of git, subversion. It relates to the repo.repository column

	$sql = "insert into commit_log (id, message_id, message_date, message_subject, date_added, commit_date, 
	          committer, description, system_id, svn_revision, repo_id, encoding_losses) values ( \
				$this->{id},
				" . $dbh->quote($this->{message_id})      . ",
				" . $dbh->quote($this->{message_date})    . ",
				" . $dbh->quote($this->{message_subject}) . ",
				" . $dbh->quote($this->{date_added})      . ",
				" . $dbh->quote($this->{commit_date})     . ",
				" . $dbh->quote($this->{committer})       . ",
				" . $dbh->quote($this->{description})     . ",
				$this->{system_id},
				" . $dbh->quote($this->{revision})        . ",
				(SELECT id FROM repo WHERE name = " . $dbh->quote($this->{repo}) . " and repository = " . $dbh->quote($this->{repository}) . "),
				$this->{encoding_losses}::boolean)";

	print "sql is $sql\n";

	$sth = $this->{dbh}->prepare($sql);
	if (!$sth->execute) {
		FreshPorts::Utilities::ReportError('warning', "Could not execute SQL $sql ... maybe invalid? " . $dbh->errstr, 1);
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

	$sql = "select commit_log.* \
              from commit_log \
             where commit_log.id = $this->{id}";

	print "sql = '$sql'\n";

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

1;
