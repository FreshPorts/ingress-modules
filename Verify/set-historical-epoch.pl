#!/usr/bin/perl -w
#
# $Id: set-historical-epoch.pl,v 1.1.2.1 2004-09-23 03:03:08 dan Exp $
#
# Copyright (c) 1999-2004 DVL Software
#

use strict;
use lib "$ENV{HOME}/scripts";
use port;
use DBI;
use database;
use utilities;

my $dbh;

my $porttorefresh;
my @PORTS;
my $sql;
my $sth;
my $row;

FreshPorts::Utilities::InitSyslog();

$dbh = FreshPorts::Database::GetDBHandle();

#
# get a list of ports to update
#

$sql = "
  select PA.category || '/' || PA.name as port, CL.id, CLP.port_version || '_' || CLP.port_revision as version, CLP.port_epoch, CL.commit_date
    from commit_log_ports CLP, commit_log CL, ports_active PA
   where PA.portepoch != '0'
     AND CLP.commit_log_id = CL.id
     AND CLP.port_id       = PA.id
     AND PA.id in (
select distinct CLPV.port_id
  from ports_active PA, commit_log_ports_vuxml CLPV
 WHERE PA.id = CLPV.port_id
   AND PA.portepoch != '0'
)

ORDER BY name, category, CL.commit_date desc
";
print "sql = $sql\n";

$sth = $dbh->prepare($sql);
$sth->execute ||
		FreshPorts::Utilities::ReportError('warning', "Could not execute SQL $sql ... maybe invalid?", 1);

my $LastPort        = undef;
my $LastVersion     = undef;
my $LastCommitLogID = undef;

LOOP:
while ($row=$sth->fetchrow_hashref()) {
	if (!defined($LastPort) || $LastPort ne $row->{'port'}) {
		$LastPort        = $row->{'port'};
		$LastVersion     = $row->{'port_version'};
		$LastCommitLogID = $row->{'id'};
		next LOOP;
	}
	if ($row->{'port_version'} ne '' && $LastVersion gt $row->{'port_version'}) {
		# we have a bump here....
#		push @PORTS, [  $LastPort, $LastRevision. $LastCommitLogID ];
		print $row;
	}
}

my $port = FreshPorts::Port->new($dbh);

foreach $porttorefresh (@PORTS) {
	my $result;

	print "found $porttorefresh\n";

	my ($port_id, $category_name, $port_name) = split /\t/,$porttorefresh, 3;

	$port->{id} = $port_id;
	if ($port->FetchByID()) {

		# needs_refresh = 0, and fetch_files = 0
		$result = $port->RefreshFromFiles(0, 0);
		print "has been refreshed ($result)\n";

		if ($result == 0) {
			$sql = "update ports set broken = " . $dbh->quote($port->{broken}) .
					" where id = $port_id";
			$sth = $dbh->prepare($sql);
			$sth->execute ||
				FreshPorts::Utilities::ReportError('warning', "Could not execute SQL $sql ... maybe invalid?", 1);

			$dbh->commit();
		} else {
			$dbh->rollback();
			print "update result is $result ******************************************\n";
		}
	} else {
		FreshPorts::Utilities::ReportError('warning', "Could not retrieve port ($port_id, $category_name, $port_name)", 1);
	}
}

$sth->finish();

#$dbh->commit();
$dbh->disconnect();

