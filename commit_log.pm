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

use Encode qw(encode);
binmode *STDOUT, ':encoding(UTF-8)';

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

	$this->{id}                 = $row->{id};
	$this->{message_id}         = $row->{message_id};
	$this->{message_date}       = $row->{message_date};
	$this->{message_subject}    = $row->{message_subject};
	$this->{date_added}         = $row->{date_added};
	$this->{commit_date}        = $row->{commit_date};
	$this->{committer}          = $row->{committer};
	$this->{committer_name}     = $row->{committer_name};
	$this->{committer_email}    = $row->{committer_email};
	$this->{author_name}        = $row->{author_name};
	$this->{author_email}       = $row->{author_email};
	$this->{description}        = $row->{description};
	$this->{encoding_losses}    = $row->{encoding_losses};
	$this->{system_id}          = $row->{system_id};
	$this->{revision}           = $row->{revision};
	$this->{repo}               = $row->{repo};
	$this->{commit_hash_short}  = $row->{commit_hash_short};
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
	
	print $dbh->quote($this->{repo}) . " and repository = " . $dbh->quote($this->{repository}) . ")";
	
	$sql = "insert into commit_log (id, message_id, message_date, message_subject, date_added, commit_date, 
	          committer, committer_name, committer_email, author_name, author_email, description, system_id, svn_revision, repo_id, encoding_losses, commit_hash_short) values ( 
				?,
				?,
				?,
				?,
				now(),
				?,
				?,
				?,
				?,
				?,
				?,
				?,
				?,
				?,
				(SELECT id FROM repo WHERE name = ? and repository = ?),
				?::boolean,
				?)";


	print "sql is $sql\n";

	$sth = $dbh->do($sql, undef,   $this->{id},
				$this->{message_id},
				$this->{message_date},
				$this->{message_subject},
				$this->{commit_date},
				$this->{committer},
				$this->{committer_name},
				$this->{committer_email},
				$this->{author_name},
				$this->{author_email},
				$this->{description},
				$this->{system_id},
				$this->{revision},
				$this->{repo}, $this->{repository},
				$this->{encoding_losses},
				$this->{commit_hash_short});

	if (!$sth) {
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
