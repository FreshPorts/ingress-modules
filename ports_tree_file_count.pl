#!/usr/bin/perl -w
#
# $Id: ports_tree_file_count.pl,v 1.1 2007-02-12 02:01:14 dan Exp $
#
# Copyright (c) 1999-2007 DVL Software
#

use strict;
use lib "$ENV{HOME}/scripts";
use config;

my $Command="/usr/bin/find $FreshPorts::Config::path_to_ports | /usr/bin/wc -l > $FreshPorts::Config::PortsTreeCount";

print $Command;

`$Command`;
