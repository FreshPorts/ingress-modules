#!/usr/bin/perl -w
#
# $Id: vuxml_mark_commits.pm,v 1.1.2.6 2005-01-25 01:31:49 dan Exp $
#
# Copyright (c) 1999-2004 DVL Software
#

package FreshPorts::vuxml_mark_commits;

use strict;
use DBI;
use database;
use constants;
use email;

sub new {
	my $this		= {};
	my $class		= shift;

	$this->{dbh}	= shift;
	bless $this;

	$this->_initialize();
	return $this
}

sub _initialize {
	my $this = shift;
}

sub CommitsForThisPackage($) {
	my $this        = shift;
    my $PackageName = shift;

	my $dbh = $this->{dbh};
    my $sth;
    my $sql;
    my $row;
	my @Commits;

    $sql = "
SELECT distinct CLP.port_id, CLP.port_version, CLP.port_revision, CLP.port_epoch
  FROM commit_log_ports CLP, ports P
 WHERE CLP.port_id       = P.id
   AND P.package_name    = '$PackageName'
   AND CLP.port_version <> ''";

#    print "sql is $sql\n";

    $sth = $dbh->prepare($sql);
    $sth->execute ||
           die "Could not execute SQL $sql ... maybe invalid?";

    while ($row = $sth->fetchrow_hashref()) {
        push @Commits, $row;
	}

	return @Commits;
}

sub EmptyCommitLogPortsVuXML() {
	# do not appear to be needed
	my $this = shift;

	my $dbh;
	my $sth;
	my $sql;

	# quote everything going to the database
	$sql = "DELETE FROM commit_log_ports_vuxml";
	$sth = $dbh->prepare($sql);
	if (!$sth->execute())  {
		FreshPorts::Utilities::ReportError('warning', "Could not execute sql", 1);
	}
}

sub ValueOrNull($) {
	my $this  = shift;
	my $Value = shift;

	my $Result;

	if (defined($Value)) {
		$Result = "= '$Value'"
	} else {
		$Result = "IS NULL";
	}

	return $Result;
}

sub MarkOneCommit($) {
	my $this        = shift;
    my $VID         = shift;
	my $PortID      = shift;
	my $CommitLogID = shift;

	my $Commit;
	my $dbh = $this->{dbh};
    my $sth;
    my $sql;

	$sql = "INSERT INTO commit_log_ports_vuxml(commit_log_id, port_id, vuxml_id)
            values ($CommitLogID, $PortID, $VID)";

#	print "sql is $sql\n";

	$sth = $dbh->prepare($sql);
	$sth->execute ||
		die "Could not execute SQL $sql ... maybe invalid?";
}

sub MarkTheseCommits($) {
	my $this    = shift;
    my $Commits = shift;

	my $Commit;
	my $dbh = $this->{dbh};
    my $sth;
    my $sql;

	print "now marking those commits\n";

	my $OldValue = $|;

	# This forces a flush right away and after every write or print
	$| = 1;

#	print "but first, let's display them all\n";
	for $Commit ( @{$Commits} ) {

#		print "==================\n";
#		for my $value (keys %$Commit) {
#			print "$value=$Commit->{$value}\n";
#		}
#
#		print "that was VULN => $Commit->{vid}\n";

		#
		# when marking multiple commits
		# we optimize by only pulling in distinct values of version, revision, epoch.
		# we don't pull in commit_log_ids.
		# this SQL will add all the commit_log_id values we need.
		#

        $sql = "
INSERT INTO commit_log_ports_vuxml(commit_log_id, port_id, vuxml_id)
SELECT commit_log_id,
       port_id,
       " . $Commit->{vid} . " as vuxml_id
  FROM commit_log_ports
 WHERE port_id       = "  . $Commit->{port_id}                    . "
   AND port_version  = '" . $Commit->{port_version}               . "'
   AND port_revision " . $this->ValueOrNull($Commit->{port_revision})  . " 
   AND port_epoch    " . $this->ValueOrNull($Commit->{port_epoch});

#		print "sql is $sql\n";
		print ".";

		$sth = $dbh->prepare($sql);
		$sth->execute ||
			die "Could not execute SQL $sql ... maybe invalid?";
	}

	$| = $OldValue;

	print "\nfinished marking those commits\n";
}

sub PackageVersion($;$;$) {
	my $this         = shift;
	my $PortVersion  = shift;
	my $PortRevision = shift;
	my $PortEpoch    = shift;

	my $PackageVersion = $PortVersion;
    if (defined($PortRevision) && $PortRevision ne '' && $PortRevision ne '0') {
		$PackageVersion .= '_' . $PortRevision
	}

	if (defined($PortEpoch) && $PortEpoch ne '' && $PortEpoch ne '0') {
		$PackageVersion .= ',' . $PortEpoch;
	}

	return $PackageVersion;
}

sub TestVersionValues($;$;$) {
	my $this       = shift;
	my $Version1   = shift;
	my $Operator   = shift;
	my $Version2   = shift;

	my $TestResult = undef;

	my %Operators = ('lt' => {
                                '<' => 1,
                             },
	                 'le' => {
	                            '<' => 1,
	                            '=' => 2,
	                         },
	                 'gt' => {
	                            '>' => 1,
	                         },
	                 'ge' => {
	                            '>' => 1,
	                            '=' => 2,
	                         },
	                 'eq' => {
	                             '=' => 1,
	                         },
	                );

	my $command = "/usr/local/sbin/pkg_version -t $Version1 $Version2";
	my $result  = `$command`;

	chomp $result;

	my $ValidResults = $Operators{$Operator};
#	while ( my ($op, $index) = each %$ValidResults) {
#		print "valid match for '$Operator' is '$op'\n"
#	}
			
	if (defined($ValidResults->{$result})) {
		$TestResult = 1;
	} else {
		$TestResult = 0;
	}

	return $TestResult;
}


sub IsCommitAffected($;$) {
	my $this          = shift;
	my $CommitVersion = shift;
	my $Range         = shift;

	my $TestResult    = undef;

	$TestResult = $this->TestVersionValues($CommitVersion, $Range->{'op1'}, $Range->{'v1'});
	if ($TestResult) {
		if (defined($Range->{'v2'})) {
			$TestResult = $this->TestVersionValues($CommitVersion, $Range->{'op2'}, $Range->{'v2'});
		}
	}

	return $TestResult;
}

sub ProcessEachRangeRecord() {
	my $this = shift;

	my $dbh = $this->{dbh};
	my $sth;
	my $sql;
	my $range;
	my $i           = 0;
	my $LastPackage = undef;

	my @Commits         = undef;
	my @AffectedCommits = ();


	$sql = "select * from vuxml_ranges();";

	print "sql is $sql\n";

	$sth = $dbh->prepare($sql);
	$sth->execute ||
		die "Could not execute SQL $sql ... maybe invalid?";

    while ($range = $sth->fetchrow_hashref()) {
		$i++;
        if (!defined($LastPackage) || $LastPackage ne $range->{'package_name'}) {
			if (defined($LastPackage)) {
				$this->MarkTheseCommits(\@AffectedCommits);
			}
			
            $LastPackage = $range->{'package_name'};

            print "We have a new package name: '$LastPackage'\n";
			@Commits = $this->CommitsForThisPackage($LastPackage);
			@AffectedCommits = ();
        } else {
            print "processing another record for that package\n";
		}
		print "*** Working on $range->{'op1'} $range->{'v1'}";
		if (defined($range->{'op2'})) {
			print "*** $range->{'op2'} $range->{'v2'}";
		}
		print "\n";

        foreach my $Commit (@Commits) {
			my $CommitVersion = $this->PackageVersion($Commit->{'port_version'},  $Commit->{'port_revision'}, $Commit->{'port_epoch'});

			print "Looking at port='$Commit->{'port_id'}' " . sprintf "%10s", $CommitVersion . ' ';
			print "$range->{'op1'} " . sprintf "%10s", $range->{'v1'};
			if (defined($range->{'op2'})) {
				print " $range->{'op1'} " . sprintf "%10s", $range->{'v1'};
			}
			print "\n";

			if ($this->IsCommitAffected($CommitVersion, $range)) {
				print "### this version is affected\n";
				$Commit->{'id'} =  $range->{'id'};

				print "***** saving away this commit:\n";
#				for my $value (keys %$Commit) {
#					print "$value=$Commit->{$value}\n";
#				}

				push @AffectedCommits, ( { commit_log_id => $Commit->{'id'},
				                           vid           => $range->{'id'},
				                           port_id       => $Commit->{'port_id'},
				                           port_version  => $Commit->{'port_version'},
				                           port_revision => $Commit->{'port_revision'},
				                           port_epoch    => $Commit->{'port_epoch'},
				                         }
				                       );

#				$Commit = undef;

				print "We have found " . scalar(@AffectedCommits) . " affected commits\n";

			}
        }
    }

	$this->MarkTheseCommits(\@AffectedCommits);

    return $i;
}

sub RecordVulnerabilitiesForThisPortVersion($;$;$) {
	my $this         = shift;
	my $CommitLogID  = shift;
	my $PortID       = shift;
	my $Package      = shift;
	my $PortVersion  = shift;
	my $PortRevision = shift;
	my $PortEpoch    = shift;

	my $dbh = $this->{dbh};
	my $sth;
	my $sql;
	my $range;
	my $i           = 0;
	my $LastPackage = undef;

	my @Commits         = undef;
	my @AffectedCommits = ();

	my $Version = $this->PackageVersion($PortVersion, $PortRevision, $PortEpoch);

	$sql = 'select * from vuxml_ranges_package(' . $dbh->quote($Package) . ')';

	print "sql is $sql\n";

	$sth = $dbh->prepare($sql);
	$sth->execute ||
		die "Could not execute SQL $sql ... maybe invalid?";

    while ($range = $sth->fetchrow_hashref()) {
		$i++;
		if ($this->IsCommitAffected($Version, $range)) {
			print '### this version is affected by ' . $range->{id} . "\n";
			$this->MarkOneCommit($range->{id}, $PortID, $CommitLogID);
		}
	}

    return $i;
}

1;
