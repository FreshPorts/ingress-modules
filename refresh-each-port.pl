#!/usr/bin/perl -w
#
# $Id: refresh-each-port.pl,v 1.2 2002-03-02 17:02:29 dan Exp $
#
# Copyright (c) 1999-2001 DVL Software
#

use strict;
use lib "$ENV{HOME}/scripts";
use port;
use DBI;
use database;
use utilities;

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

$sql = "select ports.id, categories.name as category, element.name as port 
   	      from ports, categories, element 
         where ports.category_id = categories.id 
           and ports.element_id  = element.id 
		   and element.status    = 'A'
         order by category, port ";

print "sql = $sql\n";

$sth = $dbh->prepare($sql);
$sth->execute ||
		FreshPorts::Utilities::ReportError('warning', "Could not execute SQL $sql ... maybe invalid?", 1);

my $started = 0;
while (@row=$sth->fetchrow_array) {
#	if ($row[0] == 4820 || $started) {
#		$started = 1;
		print "now reading @row\n";
		push @PORTS, "$row[0]:$row[1]:$row[2]"
#	}
}

print "press ENTER to continue";
<STDIN>;
 
my $port	= FreshPorts::Port->new($dbh);
my $element	= FreshPorts::Element->new($dbh);

foreach $porttorefresh (@PORTS) {
	my $result;

	print "found $porttorefresh\n";

	my ($port_id, $category_name, $port_name) = split /:/,$porttorefresh, 3;

	$port->{id} = $port_id;
	if ($port->FetchByID()) {

		$element->{id} = $port->{element_id};
		if (defined($element->FetchByID())) {
			print "element status = $element->{status}\n";
			print "deleted = $FreshPorts::Element::Deleted\n";
			if ($element->{status} eq $FreshPorts::Element::Deleted) {
				#
				# this port is deleted but needs refresh.
				#
				print "that port has been deleted and will not be refreshed\n";
				$result = 0;
			} else {
				# needs_refresh = 0, and fetch_files = 0
				$result = $port->RefreshFromFiles(0, 0);
				print "has been refreshed ($result)\n";
			}
		} else {
			FreshPorts::Utilities::ReportError('warning', "Could not retrieve element ($port_id, $category_name, $port_name)", 1);
		}

		if ($result == 0) {
			$port->save();
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

$dbh->commit();
$dbh->disconnect();

