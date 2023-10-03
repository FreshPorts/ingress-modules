#!/usr/local/bin/perl -w
#
# $Id: email.pm,v 1.2 2006-12-17 12:04:00 dan Exp $
#
# Copyright (c) 2001-2003 DVL Software
#

package FreshPorts::email;

use strict;
use Email::Sender::Transport::SMTP;
use Email::Stuffer;
use FreshPorts::config;
use FreshPorts::utilities;
use IO::Socket::SSL;
use Mozilla::CA;
use Try::Tiny;

IO::Socket::SSL::set_defaults(
    SSL_ca_file => Mozilla::CA::SSL_ca_file(),
);


sub SendMail($;$;$;$;$;$) {
	my $From       = shift;
	my $To	       = shift;
	my $CC         = shift;
	my $Subject    = shift;
	my $Body       = shift;
	my $HeadersRef = shift;

	my %Headers = %{$HeadersRef};	
	my $result;
	
	FreshPorts::Utilities::ReportError('LOG_ERR', "from='$From' to='$To' subject='$Subject'", 0);
	my $transport = Email::Sender::Transport::SMTP->new({
		host => $FreshPorts::Config::email_server,
		port => $FreshPorts::Config::email_port,
		ssl  => 'starttls',
		debug => 0,
	});

	my $email = Email::Stuffer->from     ($From     )
	                          ->to       ($To       )
	                          ->subject  ($Subject  )
	                          ->text_body($Body     )
	                          ->transport($transport);

	for my $header(keys %Headers) {
		$email->header($header => $Headers{$header});
	}

	try {
		$email->send; 
	}
	catch {
		# we set the last parameter to zero to avoid recursion - if 1, that function would call this function...etc.
		FreshPorts::Utilities::ReportError('LOG_ERR', "could not open Email::Sender.  from='$From' to='$To' subject='$Subject' errorcode='$_'", 0);
		exit;
	};
}

# From http://jenda.krynicky.cz/perl/Sender.pm.html
# The $Mail::Sender::SITE_HEADERS may contain headers that will be added to each mail message sent by this script, the $Mail::Sender::NO_X_MAILER disables the header item specifying that the message was sent by Mail::Sender.
# However, I cannot find any reference to NO_X_MAILER in the code
# Also, FreshPorts is now using Email::Sender, not Mail::Sender
# One day, we can remove this, but that day is not today.
# dvl - 2018.10.13
$Mail::Sender::NO_X_MAILER = 0;

1;
