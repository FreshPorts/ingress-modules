#!/usr/bin/perl -w
#
# $Id: refresh-unrefreshed-ports.pl,v 1.11 2001-12-30 23:20:42 dan Exp $
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

#
# get a list of ports to update
#

$sql = "select ports.id, categories.name as category, element.name as port, commit_log_ports.needs_refresh, commit_log_ports.commit_log_id \
        from ports, categories, element, commit_log_ports \
        where ports.category_id              = categories.id \
          and ports.element_id               = element.id
		  and commit_log_ports.port_id       = ports.id  \
          and commit_log_ports.needs_refresh <> 0 \
        order by category, port";

print "sql = $sql\n";

$sth = $dbh->prepare($sql);
$sth->execute ||
        die "Could not execute SQL $sql ... maybe invalid?";

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
				$result = $port->RefreshFromFiles($needs_refresh);
				print "has been refreshed ($result)\n";
			}
		} else {
			Sys::Syslog::syslog('warning', "Could not retrieve element ($port_id, $category_name, $port_name, $needs_refresh, $commit_log_id)");
			die "Could not retrieve element ($port_id, $category_name, $port_name, $needs_refresh, $commit_log_id)";
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

			$dbh->commit();
		} else {
			print "update result is $result ******************************************\n";
		}
	} else {
		Sys::Syslog::syslog('warning', "Could not retrieve port ($port_id, $category_name, $port_name, $needs_refresh, $commit_log_id)");
		die "Could not retrieve port ($port_id, $category_name, $port_name, $needs_refresh, $commit_log_id)";
	}
	last;
}

$sth->finish();

$dbh->commit();
$dbh->disconnect();

`touch  /home/freshports.org/lastupdate`
