#
# $Id: email.pm,v 1.1.2.4 2002-11-29 17:58:01 dan Exp $
#
# Copyright (c) 2002 DVL Software
#

package FreshPorts::email;

use strict;
use Mail::Sender;
use utilities;

sub SendMail($;$;$;$) {
	my $From 	= shift;
	my $To		= shift;
	my $Subject	= shift;
	my $Body		= shift;

	my $sender = new Mail::Sender{smtp => 'localhost', from => $From};

	my $result = $sender->Open({to => $To, subject => $Subject});
	if (ref $result) {
		$sender->SendEnc($Body);
		$sender->Close;
	} else {
		# we set the last parameter to zero to avoid recursion - if 1, that function would call this function...etc.
		FreshPorts::Utilities::ReportError('LOG_NOTICE', "could not open Mail::Sender.  from='$From' to='$To' subject='$Subject' errorcode='$result' errormsg='$Mail::Sender::Error'", 0);
		exit;
	}
}

$Mail::Sender::NO_X_MAILER = 0;

1;
