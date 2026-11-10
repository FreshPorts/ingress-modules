#!/usr/local/bin/perl -w
#
# $Id: email.pm,v 1.2 2006-12-17 12:04:00 dan Exp $
#
# Copyright (c) 2001-2026 Dan Langille
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

	# NotifyCommitter (committer_opt_in.pm) copies the system owner on mail
	# to an opted-in committer.  $CC was accepted but never used after the
	# move to Email::Stuffer in 325dd42 (2021), so that copy never arrived.
	# Empty means no Cc, which is what every other caller passes.
	if (defined($CC) && $CC ne '') {
		$email->cc($CC);
	}

	for my $header(keys %Headers) {
		$email->header($header => $Headers{$header});
	}

	#
	# A failed send is logged and returned as 0, and the caller carries on.
	#
	# send_or_die, not send: Email::Stuffer's send uses try_to_send, which
	# returns false instead of dying, so with send a failed message was
	# never logged -- it vanished without a trace.
	#
	# The catch used to exit, which is exit(0).  It never ran, because send
	# never died, but with send_or_die it would have: ReportError(..., 1)
	# mails first and dies afterwards, so with the mail server down the
	# script would have stopped here and reported success instead of dying.
	#
	my $sent = try {
		$email->send_or_die;
		1;
	}
	catch {
		# an Email::Sender::Failure stringifies with a full stack trace;
		# its message is the part worth a line in syslog
		my $error = (ref($_) && $_->can('message')) ? $_->message : $_;

		# we set the last parameter to zero to avoid recursion - if 1, that function would call this function...etc.
		FreshPorts::Utilities::ReportError('LOG_ERR', "could not send email.  from='$From' to='$To' subject='$Subject' error='$error'", 0);
		0;
	};

	return $sent;
}

# From http://jenda.krynicky.cz/perl/Sender.pm.html
# The $Mail::Sender::SITE_HEADERS may contain headers that will be added to each mail message sent by this script, the $Mail::Sender::NO_X_MAILER disables the header item specifying that the message was sent by Mail::Sender.
# However, I cannot find any reference to NO_X_MAILER in the code
# Also, FreshPorts is now using Email::Sender, not Mail::Sender
# One day, we can remove this, but that day is not today.
# dvl - 2018.10.13
$Mail::Sender::NO_X_MAILER = 0;

1;
