#!/usr/local/bin/perl -w
#
# $Id: database.pm,v 1.5 2006-12-17 12:04:00 dan Exp $
#
# Copyright (c) 2001-2026 Dan Langille
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
    #
    # Anything else is replaced by require, and said so in syslog.  This
    # list used to have 'verify-ca' with a TAB after it, so a configured
    # verify-ca never matched and was quietly turned into require, which
    # does not check the server certificate.
    my %ValidSSLModes = map { $_ => 1 } qw(disable allow prefer require verify-ca verify-full);
    if (!$ValidSSLModes{$sslmode}) {
        FreshPorts::Utilities::ReportError('warning', "ssl_mode '$sslmode' is not one libpq knows; using require", 0);
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
       
    my $dbh_pg = DBI->connect('DBI:Pg:dbname=' . $FreshPorts::Config::dbname . ';host=' . $FreshPorts::Config::host . ';sslcertmode=disable ;sslmode=' . $sslmode . ';client_encoding=UTF8', $user, $password);
    #
    # DBI->connect returns undef when it fails.  Return undef, so a caller's
    # "GetDBHandle() || die" and "if (!$dbh)" work.
    #
    # This used to test $dbh_pg->{Active} first.  On undef that quietly
    # turns $dbh_pg into an empty hash, which is true, so "could not
    # connect" was never logged, "|| die" never fired, and the caller
    # crashed later with "Can't call method prepare on unblessed reference".
    # Callers which test $dbh->{Active} still see false.
    #
    if (!$dbh_pg) {
        FreshPorts::Utilities::ReportError('err', "could not connect to $FreshPorts::Config::dbname: " . ($DBI::errstr // 'no error given'), 0);
        return undef;
    }

    $dbh_pg->{AutoCommit} = 0;

    # trying to avoid DBI db handle 0x142b99534a68 has 1 uncleared child handles during global destruction
    $dbh_pg->{AutoInactiveDestroy} = 1;

    return $dbh_pg;
}

1;
