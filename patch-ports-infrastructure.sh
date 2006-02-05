#!/bin/sh
#
# $Id: patch-ports-infrastructure.sh,v 1.1.2.4 2006-02-05 21:54:41 dan Exp $
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
cd ~/ports/Mk && patch < ~/bin/bsd.port.mk.bill-fenner-inst-files-patch
cd ~/ports/Mk && patch < ~/bin/patch.bsd.port.mk
cd ~/ports/Mk && patch < ~/bin/patch.bsd.port.subdir.mk
