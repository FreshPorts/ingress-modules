#!/usr/bin/perl -w
#
# $Id: refresh-unrefreshed-ports.pl,v 1.20 2002-02-17 20:02:57 dan Exp $
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
my $sql;
my $sth;
my @row;


FreshPorts::Utilities::InitSyslog();

$dbh = FreshPorts::Database::GetDBHandle();

my $housekeeping = FreshPorts::Housekeeping->new($dbh);

#
# get a list of ports to update
#

$sql = "select ports.id, categories.name as category, element.name as port, commit_log_ports.needs_refresh, commit_log_ports.commit_log_id 
        from ports, categories, element, commit_log_ports 
        where ports.category_id              = categories.id 
          and ports.element_id               = element.id
		  and commit_log_ports.port_id       = ports.id  
          and commit_log_ports.needs_refresh <> 0 
		  and element.status				 = 'A'
        order by category, port";

print "sql = $sql\n";

$sth = $dbh->prepare($sql);
$sth->execute ||
		FreshPorts::Utilities::ReportError('warning', "Could not execute SQL $sql ... maybe invalid?", 1);

while (@row=$sth->fetchrow_array) {
   print "now processing @row\n";
   push @PORTS, "$row[0]:$row[1]:$row[2]:$row[3]:$row[4]"
}
 
my $port				= FreshPorts::Port->new($dbh);
my $element				= FreshPorts::Element->new($dbh);
my $commit_log_ports	= FreshPorts::CommitLogPorts->new($dbh);

foreach $porttorefresh (@PORTS) {
	my $result;

	print "found $porttorefresh\n";

	my ($port_id, $category_name, $port_name, $needs_refresh, $commit_log_id) = split /:/,$porttorefresh, 5;

	$port->{id} = $port_id;
	if ($port->FetchByID()) {

		$element->{id} = $port->{element_id};
		if (defined($element->FetchByID())) {
			if ($element->{status} eq $FreshPorts::Element::Deleted) {
				#
				# this port is deleted but needs refresh.
				#
				print "that port has been deleted and will not be refreshed\n";
				$result = 0;
			} else {
				$result = $port->RefreshFromFiles($needs_refresh, 1);
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
			$commit_log_ports->{saved}			= 1;	# this forces an update, instead of an insert

			$commit_log_ports->save();

			#
			# let others know that a refresh has been completed
			# so that caching of pages can be properly done.
			#
			print " &&&&&&&&&&&&&&&&& setting housekeeping->refreshdone\n";
			$housekeeping->refreshdone();

			#
			# commit everything we've done.  we don't want it falling over during
			# the daily summary creation and then doing a rollback.
			#
			$dbh->commit();
		} else {
			print "update result is $result ******************************************\n";
			$dbh->rollback();
		}
	} else {
		FreshPorts::Utilities::ReportError('warning', "Could not retrieve port ($port_id, $category_name, $port_name, $needs_refresh, $commit_log_id)", 1);
	}
}

$sth->finish();

$dbh->commit();
$dbh->disconnect();