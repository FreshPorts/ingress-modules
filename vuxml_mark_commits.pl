#!/usr/bin/perl -w
#
# $Id: vuxml_mark_commits.pl,v 1.1.2.3 2004-09-21 23:35:59 dan Exp $
#
# Copyright (c) 1999-2004 DVL Software
#

use strict;
use DBI;
use database;
use constants;
use email;

sub CommitsForThisPackage($;$) {
    my $dbh         = shift;
    my $PackageName = shift;

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

sub ValueOrNull($) {
	my $Value = shift;

	my $Result;

	if (defined($Value)) {
		$Result = "= '$Value'"
	} else {
		$Result = "IS NULL";
	}

	return $Result;
}

sub DisplayTheseCommits($;$) {
    my $dbh     = shift;
    my $Commits = shift;

	my $Commit;
    my $sth;
    my $sql;

	print "now marking those commits\n";

	print "but first, let's display them all\n";
	for $Commit ( @{$Commits} ) {

		print "==================\n";
		for my $value (keys %$Commit) {
			print "$value=$Commit->{$value}\n";
		}
        $sql = "
INSERT INTO commit_log_ports_vuxml(commit_log_id, port_id, vuxml_id)
SELECT commit_log_id,
       port_id,
       " . $Commit->{vid} . " as vuxml_id
  FROM commit_log_ports
 WHERE port_id       = "  . $Commit->{port_id}                    . "
   AND port_version  = '" . $Commit->{port_version}               . "
   AND port_revision = " . ValueOrNull($Commit->{port_revision})  . " 
   AND port_revision = " . ValueOrNull($Commit->{port_epoch});

	    print "sql is $sql\n";
	}
}

sub MarkTheseCommits($;$) {
    my $dbh     = shift;
    my $Commits = shift;

	my $Commit;
    my $sth;
    my $sql;

	print "now marking those commits\n";

	print "but first, let's display them all\n";
	for $Commit ( @{$Commits} ) {

		print "==================\n";
#		for my $value (keys %$Commit) {
#			print "$value=$Commit->{$value}\n";
#		}

		print "that was VULN => $Commit->{vid}\n";

        $sql = "
INSERT INTO commit_log_ports_vuxml(commit_log_id, port_id, vuxml_id)
SELECT commit_log_id,
       port_id,
       " . $Commit->{vid} . " as vuxml_id
  FROM commit_log_ports
 WHERE port_id       = "  . $Commit->{port_id}                    . "
   AND port_version  = '" . $Commit->{port_version}               . "'
   AND port_revision " . ValueOrNull($Commit->{port_revision})  . " 
   AND port_epoch    " . ValueOrNull($Commit->{port_epoch});

    print "sql is $sql\n";

       $sth = $dbh->prepare($sql);
       $sth->execute ||
              die "Could not execute SQL $sql ... maybe invalid?";
	}

	print "finished marking those commits\n";

}

sub PackageVersion($;$;$) {
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

sub ProcessEachRangeRecord($) {

    my $dbh = shift;
    my $sth;
    my $sql;
    my $row;
    my $i           = 0;
    my $LastPackage = undef;

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


    my @Commits         = undef;
	my @AffectedCommits = ();


    $sql = "select * from vuxml_ranges();";

    print "sql is $sql\n";

    $sth = $dbh->prepare($sql);
    $sth->execute ||
           die "Could not execute SQL $sql ... maybe invalid?";

    while ($row = $sth->fetchrow_hashref()) {
		$i++;
        if (!defined($LastPackage) || $LastPackage ne $row->{'package_name'}) {
			if (defined($LastPackage)) {
				MarkTheseCommits($dbh, \@AffectedCommits);
#				DisplayTheseCommits($dbh, \@AffectedCommits);
#				exit;
			}
			
            $LastPackage = $row->{'package_name'};

            print "We have a new package name: '$LastPackage'\n";
			@Commits = CommitsForThisPackage($dbh, $LastPackage);
			@AffectedCommits = ();
        } else {
            print "processing another record for that package\n";
		}
		print "*** Working on $row->{'op1'} $row->{'v1'}";
		if (defined($row->{'op2'})) {
			print "*** $row->{'op2'} $row->{'v2'}";
		}
		print "\n";

		my $ValidResults = $Operators{$row->{'op1'}};
		while ( my ($op, $index) = each %$ValidResults) {
			print "valid match for '$row->{'op1'}' is '$op'\n"
		}


        foreach my $Commit (@Commits) {
			my $CommitVersion = PackageVersion($Commit->{'port_version'},  $Commit->{'port_revision'}, $Commit->{'port_epoch'});
#			print "'$Commit->{'port_id'}', '$CommitVersion'\n";

			my $command = "/usr/local/sbin/pkg_version -t $CommitVersion $row->{'v1'}";
			my $result  = `$command`;

			chomp $result;

			print "Looking at port='$Commit->{'port_id'}' with $command' gives '$result'\n";
			if (defined($ValidResults->{$result})) {
				print "### this version is affected\n";
				$Commit->{'id'} =  $row->{'id'};

				print "***** saving away this commit:\n";
				for my $value (keys %$Commit) {
					print "$value=$Commit->{$value}\n";
				}

				push @AffectedCommits, ( { commit_log_id => $Commit->{'id'},
				                           vid           => $row->{'id'},
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

	MarkTheseCommits($dbh, \@AffectedCommits);

    return $i;
}


my $dbh = FreshPorts::Database::GetDBHandle();

my $i = ProcessEachRangeRecord($dbh);

$dbh->commit();

$dbh->disconnect();

print "\nAll $i VuXML range records processed.\n";

