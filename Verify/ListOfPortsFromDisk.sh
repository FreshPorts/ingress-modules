#!/bin/sh
#
# $Id: ListOfPortsFromDisk.sh,v 1.1.2.1 2002-05-19 18:42:54 dan Exp $
#
# Copyright (c) 2001-2002 DVL Software
#
# This script will take what it finds within PORTSDIR
# and compiles a list of the ports it finds.
# It then uses this list to verify things against the 
# FreshPorts database
#

PORTSDIR=/usr/ports
TMPFILE=/tmp/list-of-ports.txt

cd ${PORTSDIR}
find * -maxdepth 1 -type d |  \
         egrep -v "^Mk|^Templates|^Tools|^distfiles|*/pkg$" | \
         grep "/" > ~/${TMPFILE}


cat ~/list-of-ports.txt | perl ./INDEX-verify-ports.pl
