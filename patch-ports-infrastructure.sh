#!/bin/sh
#
# $Id: patch-ports-infrastructure.sh,v 1.1.2.2 2004-12-19 23:19:06 dan Exp $
#
# Copyright (c) 2001-2003 DVL Software
#

if [ ! -f config.sh ]
then
	echo "config.sh not found..."
	exit 1
fi

. config.sh

if [ $OFFLINE = 1 ]
then
	exit 0
fi

cd ~/ports/Mk && patch < ~/bin/bsd.port.mk.master-slave-patch
