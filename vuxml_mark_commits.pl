#!/usr/bin/perl -w
#
# $Id: vuxml_mark_commits.pl,v 1.1.2.1 2004-09-20 19:55:53 dan Exp $
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
        $i++;
        if ($LastPackage ne $row->{'package_name'}) {
            $LastPackage = $row->{'package_name'};
            print "We have a new package name: '$LastPackage'\n";
			@Commits = CommitsForThisPackage($dbh, $LastPackage);
        } else {
            print "processing another record for that package\n";
		}
        foreach my $Commit (@Commits) {
			print "'$Commit->{'port_id'}', '$Commit->{'port_version'}', '$Commit->{'port_revision'}', '$Commit->{'port_epoch'}'\n";
        }
    }

    return $i;
}


      my $dbh = FreshPorts::Database::GetDBHandle();

      my $i = ProcessEachRangeRecord($dbh);

      $dbh->disconnect();

      print "\nAll $i VuXML range records processed.\n";

