#!/usr/bin/perl -w
#
# $Id: refresh-unrefreshed-ports.pl,v 1.20.2.3 2002-09-09 18:35:04 dan Exp $
#
# Copyright (c) 1999-2001 DVL Software
#

use strict;
use lib "$ENV{HOME}/scripts";
use port;
use DBI;
use database;
use utilities;
use commit_log_ports;
use housekeeping;

my $dbh;

my $maxlength=0;
my $dirname='';
my $porttorefresh;
my @PORTS;
my %Port;
my $sql;
my $sth;
my @row;

my $fetch_before_refresh = 1;


FreshPorts::Utilities::InitSyslog();

	if (($#ARGV+1) >= 1) {
		my $i;

		for ($i = 0; $i < ($#ARGV+1); $i++) {
			print "checking arg $i\n";
			if ($ARGV[$i] eq '-r') {
				# useful if we only want to use
				# what's on disk.
				print "not fetching before refresh....\n";
				$fetch_before_refresh = 0;
			}
		}
	}

$dbh = FreshPorts::Database::GetDBHandle();

my $housekeeping = FreshPorts::Housekeeping->new($dbh);

#
# get a list of ports to update
#

$sql = "select ports.id, categories.name as category, element.name as port, commit_log_ports.needs_refresh, 
			   commit_log_ports.commit_log_id, to_char(commit_log.commit_date - SystemTimeAdjust(), 'YYYY-MM-DD') as commit_date
        from ports, categories, element, commit_log_ports, commit_log
        where ports.category_id              = categories.id 
          and ports.element_id               = element.id
		  and commit_log_ports.port_id       = ports.id  
          and commit_log_ports.needs_refresh <> 0 
		  and element.status				 = 'A'
		  and commit_log.id                  = commit_log_ports.commit_log_id
        order by category, port";

print "sql = $sql\n";

$sth = $dbh->prepare($sql);
$sth->execute ||
		FreshPorts::Utilities::ReportError('warning', "Could not execute SQL $sql ... maybe invalid?", 1);

while (@row=$sth->fetchrow_array) {
	print "now processing @row\n";
	$Port{id}            = $row[0];
	$Port{category}      = $row[1];
	$Port{port}          = $row[2];
	$Port{needs_refresh} = $row[3];
	$Port{commit_log_id} = $row[4];
	$Port{commit_date}   = $row[5];

	#
	# by enclosing the has in { }
	# we are creating an anonymous hash
	#
	push @PORTS, {%Port};
}
 
my $port				= FreshPorts::Port->new($dbh);
my $element				= FreshPorts::Element->new($dbh);
my $commit_log_ports	= FreshPorts::CommitLogPorts->new($dbh);

my %DatesToRefresh;

foreach $porttorefresh (@PORTS) {
	my $result;

	my $port_id       = $porttorefresh->{id};
	my $category_name = $porttorefresh->{category};
	my $port_name     = $porttorefresh->{port};
	my $needs_refresh = $porttorefresh->{needs_refresh};
	my $commit_log_id = $porttorefresh->{commit_log_id};
	my $commit_date   = $porttorefresh->{commit_date};

	print "found $category_name/$port_name $needs_refresh $commit_log_id $commit_date \n";

	$port->{id} = $port_id;
	if ($port->FetchByID()) {
		$result = 0;
		$element->{id} = $port->{element_id};
		if (defined($element->FetchByID())) {
			if ($element->{status} eq $FreshPorts::Element::Deleted) {
				#
				# this port is deleted but needs refresh.
				#
				print "that port has been deleted and will not be refreshed\n";
				$result = 0;
			} else {
				$result = $port->RefreshFromFiles($needs_refresh, $fetch_before_refresh);
				print "refresh attempt done ($result)\n";
			}
		} else {
			FreshPorts::Utilities::ReportError('warning', "Could not retrieve element ($port_id, $category_name, $port_name, $needs_refresh, $commit_log_id)", 1);
		}

		#
		# now reset refreshed
		#
		if ($result == 0) {

			$port->save();

			$commit_log_ports->{commit_log_id}	= $commit_log_id;
			$commit_log_ports->{port_id}		= $port->{id};
			$commit_log_ports->{needs_refresh}	= 0;
			$commit_log_ports->{port_version}	= $port->{version};
			$commit_log_ports->{port_revision}	= $port->{revision};
			$commit_log_ports->{saved}			= 1;	# this forces an update, instead of an insert

			$commit_log_ports->save();

			#
			# let others know that a refresh has been completed
			# so that caching of pages can be properly done.
			#
			print " &&&&&&&&&&&&&&&&& setting housekeeping->refreshdone\n";
			$housekeeping->refreshdone($FreshPorts::Housekeeping::RefreshPorts);

			#
			# commit everything we've done.  we don't want it falling over during
			# the daily summary creation and then doing a rollback.
			#
			$dbh->commit();

			#
			# save that date away for later use
			#
			$DatesToRefresh{"$commit_date"} = "$commit_date";
		} else {
			print "update result is $result ******************************************\n";
			$dbh->rollback();
		}
	} else {
		FreshPorts::Utilities::ReportError('warning', "Could not retrieve port ($port_id, $category_name, $port_name, $needs_refresh, $commit_log_id)", 1);
	}
}

$sth->finish();

#
# now save all those commit values away
#
while ( my ($key, $value) = each %DatesToRefresh) {
	$sql = "select DailySummaryDateAdd('$key')";
	print "sql is $sql\n";

	$sth = $dbh->prepare($sql);
	if (!$sth->execute) {
		FreshPorts::Utilities::ReportError('warning', "Could not execute SQL $sql ... maybe invalid? ". $dbh->errstr, 1);
	}
}

$sth->finish();

$dbh->commit();
$dbh->disconnect();