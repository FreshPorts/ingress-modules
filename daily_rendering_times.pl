#!/usr/bin/perl -w
#
# $Id: daily_rendering_times.pl,v 1.1.2.1 2004-01-12 19:01:49 dan Exp $
#
# Copyright (c) 2004 DVL Software
#

use strict;
use lib "$ENV{HOME}/scripts";

use port;
use database; 
use DBI;

require config;

my $date;

if (($#ARGV+1) >= 1) {
	$date = $ARGV[0];
} else {
	print "USAGE : $0 date\n";
	exit 1;
}


my $dbh = FreshPorts::Database::GetDBHandle();

my $sql;
my $sth;

$sql = "select PageLoadSummaryUpdate('$date')";
$sth = $dbh->prepare($sql);
$sth->execute ||
        die "Could not execute SQL $sql ... maybe invalid?";

$sth->fetchrow_array;

#$sql = "delete from page_load_detail where date = ('$date'::date - interval '14 days')::date";
#$sth = $dbh->prepare($sql);
#$sth->execute ||
#        die "Could not execute SQL $sql ... maybe invalid?";

$sth->finish();

$dbh->commit();
$dbh->disconnect();
