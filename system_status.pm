#!/usr/bin/perl
#
# $Id: system_status.pm,v 1.1.2.1 2004-02-07 06:33:47 dan Exp $
#
# Copyright (c) 2001-2004 DVL Software
#


package FreshPorts::SystemStatus;

push (@INC, '~/scripts');

use lib "$ENV{HOME}/scripts";

use strict;
use utilities;

require constants;


sub new {
	my $this		= {};
	my $class		= shift;
	bless $this;
	$this->_initialize();
	return $this
}

sub _initialize {
}

sub Online {
	#
	# This function works only for inserts, not for updates
	#
	my $this = shift;

	if (-e "./OFFLINE") {
		return 0;
	} else {
		return 1;
	}
}

1;