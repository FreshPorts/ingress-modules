#!/usr/bin/perl
#
# $Id: cache.pm,v 1.1.2.5 2002-04-18 14:05:54 dan Exp $
#
# Copyright (c) 2001-2002 DVL Software
#

package FreshPorts::Cache;

use strict;
use config;
use utilities;

sub RefreshMainPage($) {
	my $dbh = shift;

	my $sql;
	my $sth;
	my @row;
	my $MaxCommitID;

	$sql = "select RecordLastestPortCommits();";
	print "sql = $sql\n";

	if ($sth = $dbh->prepare($sql)) {
		if ($sth->execute) {
			@row=$sth->fetchrow_array;
		} else {
			FreshPorts::Utilities::ReportError('warning', "Could not execute SQL $sql ... maybe invalid?", 0);
		}
	} else {
		FreshPorts::Utilities::ReportError('warning', "Could not prepare SQL $sql ... maybe invalid?", 0);
	}

	$sth->finish();

	$MaxCommitID = $row[0];

	return $MaxCommitID
}

sub DailySummaryDateAdd($;$) {
	my $Date	= shift;
	my $dbh		= shift;

	my $sql;
	my $sth;
	my @row;
	my $MaxCommitID;

	$sql = "select DailySummaryDateAdd('$Date');";
	print "sql = $sql\n";

	if ($sth = $dbh->prepare($sql)) {
		if ($sth->execute) {
			# do nothing
		} else {
			FreshPorts::Utilities::ReportError('warning', "Could not execute SQL $sql ... maybe invalid?", 0);
		}
	} else {
		FreshPorts::Utilities::ReportError('warning', "Could not prepare SQL $sql ... maybe invalid?", 0);
	}

	$sth->finish();

	return $MaxCommitID
}

sub DailySummaryDateRemove($;$) {
	my $Date	= shift;
	my $dbh		= shift;

	my $sql;
	my $sth;
	my @row;
	my $MaxCommitID;

	$sql = "select DailySummaryDateRemove('$Date');";
	print "sql = $sql\n";

	if ($sth = $dbh->prepare($sql)) {
		if ($sth->execute) {
			# do nothing
		} else {
			FreshPorts::Utilities::ReportError('warning', "Could not execute SQL $sql ... maybe invalid?", 0);
		}
	} else {
		FreshPorts::Utilities::ReportError('warning', "Could not prepare SQL $sql ... maybe invalid?", 0);
	}

	$sth->finish();

	return $MaxCommitID
}

sub GetMaxCommitLogPortId($) {
	my $dbh = shift;

	my $sql;
	my $sth;
	my @row;
	my $MaxCommitLogPortId;

	$sql = "select max(commit_log_id) from commit_log_ports";
	if ($sth = $dbh->prepare($sql)) {
		if ( $sth->execute) {
			@row=$sth->fetchrow_array;

			$sth->finish();
		} else {
			FreshPorts::Utilities::ReportError('warning', "Could not execute SQL $sql ... maybe invalid?", 0)
		}
	} else {
		FreshPorts::Utilities::ReportError('warning', "Could not prepare SQL $sql ... maybe invalid?", 0);
	}

	$MaxCommitLogPortId = $row[0];

	return $MaxCommitLogPortId;
}

sub CreateDailySummary($;$) {
#
# create the daily summary for the supplied date.
# CommitDateStart should be the commit date of the message
# which prompted the database update in the first place.
#

	my $CommitDateStart = shift;
	my $dbh             = shift;

	my $myrow;

	my $sql = "	select commit_log.commit_date, categories.name as category, element.name as port, 
				       commit_log_ports.port_version as version, commit_log_ports.port_revision as revision
				  from commit_log, commit_log_ports, ports, categories, element
				 where commit_date between ('" . $CommitDateStart . "'::timestamp + SystemTimeAdjust())::timestamp
				                       and ('" . $CommitDateStart . "'::timestamp + SystemTimeAdjust() + INTERVAL '1 DAY')::timestamp
				   and commit_log_ports.commit_log_id = commit_log.id
				   and ports.id                       = commit_log_ports.port_id
				   and ports.category_id              = categories.id
				   and ports.element_id               = element.id
				 ORDER by commit_log.commit_date desc, category, port";

	print "\$sql='$sql'<BR>\n";

	my $sth = $dbh->prepare($sql);

	$sth->execute ||
		FreshPorts::Utilities::ReportError('warning', "Could not execute SQL statement\n--$sql--\n... maybe invalid?", 1);

	print "$sql\n";

	umask(02);
	# create the output file name gradually, ensuring the directories exist

	my $OutputFile = $FreshPorts::Config::DailySummaryDir . "/" . substr($CommitDateStart, 0, 4);

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

	$OutputFile .= "/" . substr($CommitDateStart, 5, 2);
	if (-d $OutputFile) {
		print "'$OutputFile' exists\n";
	} else {
		print "   trying to mkdir '$OutputFile'\n";
		if (mkdir $OutputFile, 0775) {
		} else {
		print "Could not create directory $OutputFile\n";
			return 2;
		}
	}

	$OutputFile .= "/" .  substr($CommitDateStart, 8, 2) . ".inc";
	print "trying to open '$OutputFile'\n";
   
	if (open(FILE, ">$OutputFile")) {
		print "that file was opened.  now writing output\n";
		my $count =0;
		while ($myrow = $sth->fetchrow_hashref()) {
			print $myrow->{commit_date} .': '. $myrow->{category}. '/' . $myrow->{port} . "\n";
			print FILE "<A HREF=\"$myrow->{category}/$myrow->{port}/\">";
			print FILE '<FONT SIZE="-1">' . $myrow->{port} . ' ';

			#
			# when a port is first saved, it does not contain a version.
			# that is set when the port is refreshed.
			# the daily summary is not created until this refresh.
			# but in case we have parallel processes, this check
			# should avoid a nasty little warning message.
			#
			if (defined($myrow->{version})) {
				print FILE $myrow->{version};
			}
			if (defined($myrow->{revision}) && ($myrow->{revision} > 0)) {
				print FILE '-' . $myrow->{revision};
			}
			print FILE "</FONT></A><BR>\n";     
			$count++;
		}

		print "i wrote out $count records\n";

		close FILE;
	} else {
		print "could not open '$OutputFile'\n";
		return 3;
	}
   
	return 0;
}

sub RefreshDailySummaries($) {
	my $dbh = shift;

	my $sql;
	my $sth;
	my @row;
	my $RefreshDate;
	my $RefreshCount = 0;
	my @RefreshDates;

	print "RefreshDailySummaries: start\n";

	$sql = "SELECT refresh_date
			  FROM daily_refreshes
		  ORDER BY refresh_date";

	print "sql = $sql\n";

	if ($sth = $dbh->prepare($sql)) {
		if ($sth->execute) {
			$RefreshCount = 0;
			while (@row = $sth->fetchrow_array()) {
				
				$RefreshDate = $row[0];

				$RefreshDates[$RefreshCount] = $RefreshDate;

				$RefreshCount++;
				print "RefreshDailySummaries: refreshing $RefreshDate\n";

				CreateDailySummary($RefreshDate, $dbh);
			}

			# remove those dates from the refresh table
			my $i;
			for ($i = 0; $i < $RefreshCount; $i++) {
				DailySummaryDateRemove($RefreshDates[$i], $dbh);
			}

		} else {
			FreshPorts::Utilities::ReportError('warning', "Could not execute SQL $sql ... maybe invalid?", 0);
		}
	} else {
		FreshPorts::Utilities::ReportError('warning', "Could not prepare SQL $sql ... maybe invalid?", 0);
	}

	$sth->finish();

	print "RefreshDailySummaries: finishes\n";

	return $RefreshCount;
}

1;
