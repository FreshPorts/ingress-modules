#!/usr/bin/perl -w
#
# $Id: ports_tree_file_count.pl,v 1.2 2007-10-11 18:15:33 dan Exp $
#
# Copyright (c) 1999-2007 DVL Software
#

use strict;
use lib "$ENV{HOME}/scripts";
use config;

# this is hardcoded to HEAD for now
my $Command="/usr/bin/find $FreshPorts::Config::path_to_tree/PORTS-$FreshPorts::Constants::HEAD | /usr/bin/wc -l > $FreshPorts::Config::PortsTreeCount";

# print $Command;

`$Command`;
