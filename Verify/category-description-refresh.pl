#!/usr/bin/perl -w
#
# $Id: category-description-refresh.pl,v 1.1.2.1 2006-02-05 21:49:51 dan Exp $
#
# Copyright (c) 1999-2004 DVL Software
#

use strict;
use lib "../";
use category;
use DBI;
use database;
use utilities;
use constants;
use committer_opt_in;
my $dbh;

my $categorytorefresh;
my @CATEGORIES;
my $sql;
my $sth;
my @row;

FreshPorts::Utilities::InitSyslog();

$dbh = FreshPorts::Database::GetDBHandle();

#
# get a list of categories to update
#

$sql = "
  SELECT id,
         name
    FROM categories
ORDER BY name ";

print "sql = $sql\n";

$sth = $dbh->prepare($sql);
$sth->execute ||
		FreshPorts::Utilities::ReportError('warning', "Could not execute SQL $sql ... maybe invalid?", 1);

while (@row=$sth->fetchrow_array) {
#	print "now reading @row\n";
	push @CATEGORIES, "$row[0]\t$row[1]"
}

my $category = FreshPorts::Category->new($dbh);

foreach $categorytorefresh (@CATEGORIES) {
	my $result;

#	print "found $categorytorefresh\n";

	my ($id, $name) = split /\t/,$categorytorefresh, 2;

	$category->{id} = $id;
	if ($category->FetchByID()) {
		my $name = $category->{name} . ' ' . $category->{id} . "\n";

		print 'name is ' . $name;

		$category->RefreshDescription();
#		$category->save();
		print $category->{name} . ': ' . $category->{description} . "\n";

		$category->save();
	} else {
		FreshPorts::Utilities::ReportError('warning', "Could not retrieve category ($id)", 1);
	}
}

$sth->finish();

$dbh->commit();
$dbh->disconnect();

