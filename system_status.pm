#!/usr/local/bin/perl
#
# $Id: system_status.pm,v 1.3 2007-12-30 18:36:46 dan Exp $
#
# Copyright (c) 2001-2004 DVL Software
#


package FreshPorts::SystemStatus;

use strict;
use utilities;
use config;

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
	my $this = shift;

	if (-e "$FreshPorts::Config::scriptpath/OFFLINE") {
		return 0;
	} else {
		return 1;
	}
}

1;
