#!/usr/bin/perl -w
#
# $Id: vuxml_mark_commits.pl,v 1.1.2.2 2004-09-20 20:53:22 dan Exp $
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

sub PackageVersion($;$;$) {
	my $PortVersion  = shift;
	my $PortRevision = shift;
	my $PortEpoch    = shift;

	my $PackageVersion = $PortVersion;
    if ($PortRevision != '' && $PortRevision != '0') {
		$PackageVersion .= '_' . $PortRevision
	}

	if ($PortEpoch != '' && $PortEpoch != '0') {
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
    my $LastPackage = '';

    my @Commits;


    $sql = "select * from vuxml_ranges();";

    print "sql is $sql\n";

    $sth = $dbh->prepare($sql);
    $sth->execute ||
           die "Could not execute SQL $sql ... maybe invalid?";

    while ($row = $sth->fetchrow_hashref()) {
        if ($LastPackage ne $row->{'package_name'}) {
            $LastPackage = $row->{'package_name'};
            print "We have a new package name: '$LastPackage'\n";
			@Commits = CommitsForThisPackage($dbh, $LastPackage);
        } else {
            print "processing another record for that package\n";
		}
		print "*** Working on $row->{'op1'} $row->{'v1'}";
		if (defined($row->{'op2'})) {
			print "*** $row->{'op2'} $row->{'v2'}";
		}
		print "\n";
        foreach my $Commit (@Commits) {
			print "'$Commit->{'port_id'}', '$Commit->{'port_version'}', '$Commit->{'port_revision'}', '$Commit->{'port_epoch'}'\n";
			my $CommitVersion = PackageVersion($Commit->{'port_version'},  $Commit->{'port_revision'}, $Commit->{'port_epoch'});

			my $command = "/usr/local/sbin/pkg_version -t $CommitVersion $row->{'v1'}";
			my $result  = `$command`;

			chomp $result;

			print "'$command' gives '$result'\n";
        }
    }

    return $i;
}


      my $dbh = FreshPorts::Database::GetDBHandle();

      my $i = ProcessEachRangeRecord($dbh);

      $dbh->disconnect();

      print "\nAll $i VuXML range records processed.\n";

