#
# $Id: email.pm,v 1.1.2.1 2002-11-24 16:27:39 dan Exp $
#
# Copyright (c) 2002 DVL Software
#

package FreshPorts::email;

use strict;
use Mail::Sender;

sub SendMail($;$;$;$) {
	my $From 	= shift;
	my $To		= shift;
	my $Subject	= shift;
	my $Body		= shift;

	my $sender = new Mail::Sender{smtp => 'localhost', from => $From};

	$sender->Open({to => $To, subject => $Subject});
	$sender->SendLineEnc($Body);
	$sender->Close;
}

$Mail::Sender::NO_X_MAILER = 0;

1;
