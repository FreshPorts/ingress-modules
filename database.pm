#!/usr/local/bin/perl
#
# $Id: database.pm,v 1.5 2006-12-17 12:04:00 dan Exp $
#
# Copyright (c) 2001-2003 DVL Software
#

package FreshPorts::Database;

use strict;
use utilities;
use DBI;
use Sys::Syslog;
use constants;

require config;

sub GetDBHandle {
    my %opts = @_;
    
    my $user;
    my $password;

    # was anything passed in
    my $ConnectionType = delete($opts{$FreshPorts::Constants::DB_ConnectionType});

    # assign a default value
    if (!defined($ConnectionType)) {
        $ConnectionType = $FreshPorts::Constants::DB_ConnectionType_Commits;
    }

    if ($ConnectionType eq $FreshPorts::Constants::DB_ConnectionType_Commits) {
        $user     = $FreshPorts::Config::user;
        $password = $FreshPorts::Config::password;
     }

     if ($ConnectionType eq $FreshPorts::Constants::DB_ConnectionType_ReadOnly) {
         $user     = $FreshPorts::Config::user_readonly;
         $password = $FreshPorts::Config::password_readonly;
     }

     if ($ConnectionType eq $FreshPorts::Constants::DB_ConnectionType_Listener) {
         $user     = $FreshPorts::Config::user_listening;
         $password = $FreshPorts::Config::password_listening;
     }
       
	my $dbh_pg = DBI->connect('DBI:Pg:dbname=' . $FreshPorts::Config::dbname . ';host=' . $FreshPorts::Config::host . ';sslmode=require', $user, $password);
	if ($dbh_pg->{Active}) {
		$dbh_pg->{AutoCommit} = 0;

		if (!$dbh_pg) {
			FreshPorts::Utilities::ReportError('warning', "could not connect to $FreshPorts::Config::dbname", 1);
		}
	}

	return $dbh_pg;
}

1;