#!/usr/bin/perl -w
#
# $Id: vuxml_mark_commits.pl,v 1.1.2.5 2004-10-03 02:20:15 dan Exp $
#
# Copyright (c) 1999-2004 DVL Software
#

use strict;
use DBI;
use database;
use constants;
use email;
use vuxml_mark_commits;

my $dbh = FreshPorts::Database::GetDBHandle();

my $CommitMarker = FreshPorts::vuxml_mark_commits->new($dbh);

my $i = $CommitMarker->ProcessEachRangeRecord();

$dbh->commit();

$dbh->disconnect();

print "\nAll $i VuXML range records processed.\n";

