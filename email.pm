#
# $Id: email.pm,v 1.1.2.10 2003-09-11 20:09:33 dan Exp $
#
# Copyright (c) 2001-2003 DVL Software
#

package FreshPorts::email;

use strict;
use Mail::Sender;

use config;
use utilities;


sub SendMail($;$;$;$;$;$) {
	my $From 	= shift;
	my $To		= shift;
	my $CC      = shift;
	my $Subject	= shift;
	my $Body	= shift;
	my $Headers = shift;
	
	my $result;

	my $sender = new Mail::Sender{
            smtp   => $FreshPorts::Config::email_server,
            from   => $From,
            port   => $FreshPorts::Config::email_port,
            client => $FreshPorts::Config::email_client
            };

	$result = $sender->Open({to => $To, cc => $CC, subject => $Subject, headers=> $Headers});

	if (ref $result) {
		$sender->SendEnc($Body);
		$sender->Close;
	} else {
		# we set the last parameter to zero to avoid recursion - if 1, that function would call this function...etc.
		FreshPorts::Utilities::ReportError('LOG_ERR', "could not open Mail::Sender.  from='$From' to='$To' subject='$Subject' errorcode='$result' errormsg='$Mail::Sender::Error'", 0);
		exit;
	}
}



$Mail::Sender::NO_X_MAILER = 0;

1;
