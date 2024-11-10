#!/usr/local/bin/perl -w
#
# $Id: system_status.pm,v 1.3 2007-12-30 18:36:46 dan Exp $
#
# Copyright (c) 2001-2004 DVL Software
#


package FreshPorts::SystemStatus;

use strict;
use FreshPorts::utilities;
use FreshPorts::config;

require FreshPorts::constants;


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

# The existence of this script means the system is offline.
# scripts etc should not run.
# We don't use one for the Ingress user because scripts don't run as that user.
# If you want to stop Ingress scripts, stop the ingress service.
# There are many cronjobs and periodic scripts which run as the FreshPorts user.

	if (-e "$FreshPorts::Config::Offline") {
		return 0;
	} else {
		return 1;
	}
}

1;
