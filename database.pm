#!/usr/local/bin/perl
#
# $Id: database.pm,v 1.5 2006-12-17 12:04:00 dan Exp $
#
# Copyright (c) 2001-2003 DVL Software
#

package FreshPorts::Database;

use strict;
use FreshPorts::utilities;
use DBI;
use Sys::Syslog;
use FreshPorts::constants;

require FreshPorts::config;

sub GetDBHandle {
    my %opts = @_;
    
    my $user;
    my $password;

    # was anything passed in
    my $ConnectionType = delete($opts{$FreshPorts::Constants::DB_ConnectionType});

    # was anything passed in
    my $sslmode = $FreshPorts::Config::ssl_mode;

    # assign a default value for $ConnectionType
    if (!defined($ConnectionType)) {
        $ConnectionType = $FreshPorts::Constants::DB_ConnectionType_Commits;
    }

    # assign a default value
    if (!defined($sslmode)) {
        $sslmode = 'require';
    }

    # check values for $sslmode
    # as found at https://www.postgresql.org/docs/current/static/libpq-ssl.html
    if ($sslmode ne 'disable' && $sslmode ne 'allow' && $sslmode ne 'prefer' && $sslmode ne 'rneuire' && $sslmode ne 'verify-ca	' && $sslmode ne 'verify-full') {
        $sslmode = 'require';
    }

    # check values for $ConnectionType
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
       
    my $dbh_pg = DBI->connect('DBI:Pg:dbname=' . $FreshPorts::Config::dbname . ';host=' . $FreshPorts::Config::host . ';sslmode=' . $sslmode . ';client_encoding=UTF8', $user, $password);
    if ($dbh_pg->{Active}) {
        $dbh_pg->{AutoCommit} = 0;

        if (!$dbh_pg) {
            FreshPorts::Utilities::ReportError('warning', "could not connect to $FreshPorts::Config::dbname", 1);
        }
    }

    return $dbh_pg;
}

1;
