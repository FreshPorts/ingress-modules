#!/usr/bin/perl -w
#
# $Id: hourly_stats.pl,v 1.1.2.1 2002-05-19 20:24:19 dan Exp $
#
# Copyright (c) 2001-2002 DVL Software
#

use strict;
use lib "$ENV{HOME}/scripts";

use port;
use database; 
use DBI;

my %Queries = (
	new       => 'select Stats_PortCount()',
	broken    => 'select Stats_PortCountBroken()',
	forbidden => 'select Stats_PortCountForbidden()',
	today     => 'select Stats_PortCountNewToday()',
	yesterday => 'select Stats_PortCountNewYesterday()',
	week      => 'select Stats_PortCountNewThisWeek()',
);

my %Stats;

require config;

sub GetStatistics($) {
	my $dbh = shift;

	my @row;

	while (my ($key, $query) = each %Queries) {
		print "processing $key => $query";
		my $sth = $dbh->prepare($query);

		$sth->execute ||
			FreshPorts::Utilities::ReportError('warning', "Could not execute SQL statement\n--$query--\n... maybe invalid?", 1);

		@row = $sth->fetchrow_array;
		$Stats{$key} = $row[0];

		print " ==  $Stats{$key}\n";
		$sth->finish();
	}
}


sub CreateHourlySummary() {

	my $myrow;

	umask(02);
	# create the output file name gradually, ensuring the directories exist

	my $OutputFile = $FreshPorts::Config::HourlySummaryDir;

	if (-d $OutputFile) {
		print "'$OutputFile' exists\n";
	} else {
		print "'$OutputFile' does not exist\n";
		print "   trying to mkdir '$OutputFile'\n";
		if (mkdir $OutputFile, 0775) {
		} else {
			print "Could not create directory $OutputFile\n";
			return 1;
		}
	}

	$OutputFile .= "/stats.html";
	print "trying to open '$OutputFile'\n";
   
	if (open(FILE, ">$OutputFile")) {
		print "that file was opened.  now writing output\n";
		my $count =0;

		print FILE '<TABLE WIDTH="100%">' . "\n";
		print FILE '<TR><TD><A HREF="/categories.php">Port count</A></TD> <TD ALIGN="right">'      . $Stats{new}       . '</TD></TR>' . "\n";

		print FILE '<TR><TD><A HREF="/ports-broken.php">Broken</A></TD>     <TD ALIGN="right">'    . $Stats{broken}    . '</TD></TR>' . "\n";

		print FILE '<TR><TD><A HREF="/ports-forbidden.php">Forbidden</A></TD>  <TD ALIGN="right">' . $Stats{forbidden} . '</TD></TR>' . "\n";

		print FILE '<TR><TD><A HREF="/ports-new.php">new today</A></TD>    <TD ALIGN="right">'     . $Stats{today}     . '</TD></TR>' . "\n";

		print FILE '<TR><TD><A HREF="/ports-new.php">new yesterday</A></TD><TD ALIGN="right">'     . $Stats{yesterday} . '</TD></TR>' . "\n";

		print FILE '<TR><TD><A HREF="/ports-new.php">new last week</A></TD><TD ALIGN="right">'     . $Stats{week}      . '</TD></TR>' . "\n";
		print FILE '</TABLE>' . "\n";


		close FILE;
	} else {
		print "could not open '$OutputFile'\n";
		return 3;
	}
   
	return 0;
}



my $dbh = FreshPorts::Database::GetDBHandle();

GetStatistics($dbh);
CreateHourlySummary();

$dbh->disconnect();
