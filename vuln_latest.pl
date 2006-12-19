#!/usr/bin/perl -w
#
# $Id: vuln_latest.pl,v 1.1.2.2 2006-12-19 00:39:33 dan Exp $
#
# Copyright (c) 2006 DVL Software
#

use strict;

use port;
use database; 
use DBI;
use commit_log_ports_ignore;
use system_status;

require config;

sub CreateVulnHTML($) {

	my $dbh = shift;

	umask(02);
	# create the output file name gradually, ensuring the directories exist

	my $OutputFileDir = $FreshPorts::Config::HourlySummaryDir;

	if (-d $OutputFileDir) {
		print "'$OutputFileDir' exists\n";
	} else {
		print "'$OutputFileDir' does not exist\n";
		print "   trying to mkdir '$OutputFileDir'\n";
		if (mkdir $OutputFileDir, 0775) {
		} else {
			print "Could not create directory $OutputFileDir\n";
			return 1;
		}
	}

	my $OutputFile = "$OutputFileDir/vuln-latest.html.tmp";
	print "trying to open '$OutputFile'\n";
   
	if (open(FILE, ">$OutputFile")) {
		print "that file was opened.  now writing output\n";
		my $count =0;

		my $row;
		my $query = "
  SELECT DISTINCT
         PA.category,
         PA.name AS port,
         coalesce(V.date_modified, V.date_entry, V.date_discovery) AS date,
         V.vid,
         to_char(coalesce(V.date_modified, V.date_entry, V.date_discovery)::date, 'Mon DD') AS date_formatted,
         V.date_modified IS NOT NULL AS new
    FROM commit_log_ports_vuxml CLPV, vuxml V, ports_all PA
   WHERE CLPV.vuxml_id = V.id
     AND CLPV.port_id  = PA.id
ORDER BY coalesce(V.date_modified, V.date_entry, V.date_discovery) desc, category, name
   LIMIT 15";
        
		my $sth = $dbh->prepare($query);

		$sth->execute ||
			FreshPorts::Utilities::ReportError('warning', "Could not execute SQL statement\n--$query--\n... maybe invalid?", 1);

		print FILE '<TABLE WIDTH="100%">' . "\n";
		while ($row = $sth->fetchrow_hashref()) {
			print FILE '<TR><TD align="left"><A HREF="' . $FreshPorts::Constants::VUXML_URL . $row->{vid} . '.html">' . $row->{port};
			if (!$row->{new}) {
				print FILE '<sup>*</sup>';
			}
			print FILE '</A></TD>' . 
			     '<TD nowrap ALIGN="right">' . $row->{date_formatted} . '</TD></TR>' . "\n";
		}
		print FILE '</TABLE>' . "\n";

		$sth->finish();


		print "closing file\n";
		close FILE;

		print "renaming '$OutputFile' to '$OutputFileDir/vuln-latest.html'\n";
		rename "$OutputFile", "$OutputFileDir/vuln-latest.html";
	} else {
		print "could not open '$OutputFile'\n";
		return 3;
	}
   
	return 0;
}


#
# see if the system is online.
# If not, exit.
#
my $SystemStatus = FreshPorts::SystemStatus->new();
if (!$SystemStatus->Online()) {
	exit 0;
}


my $dbh = FreshPorts::Database::GetDBHandle();

CreateVulnHTML($dbh);

$dbh->disconnect();
