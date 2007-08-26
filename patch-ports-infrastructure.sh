#!/bin/sh
#
# $Id: patch-ports-infrastructure.sh,v 1.3 2007-08-26 02:40:57 dan Exp $
#
# Copyright (c) 2001-2003 DVL Software
#

if [ ! -f config.sh ]
then
	echo "config.sh not found..."
	exit 1
fi

. config.sh

cd ${PORTSDIR}/Mk
patch < ${SCRIPTDIR}/patches/bsd.port.mk.master-slave-patch
patch < ${SCRIPTDIR}/patches/bsd.port.mk.bill-fenner-inst-files-patch
patch < ${SCRIPTDIR}/patches/patch.bsd.port.subdir.mk
