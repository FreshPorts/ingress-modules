#!/bin/sh
#
# $Id: process_updating.sh,v 1.2 2006-12-17 12:04:02 dan Exp $
#
# Copyright (c) 2003-2004 DVL Software Limited
#
# Check to see if the switch is set, and if so, load the
# /usr/ports/UPDATING file into the database
#
#  3-59/7  *   *   *   *  cd $DIR && ./process_updating.sh >> /dev/null
#
# where $DIR is the directory in which this file exists.
#
# file switch, set by commit processing script
# That file 

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

if [ "${UPDATINGFLAGFILE}x" = 'x' -o "${PORTSDIR}x" = 'x' ]
then
	echo "please set UPDATINGFLAGFILE and PORTSDIR in config.sh"
	exit 1
fi

if [ -r ${UPDATINGFLAGFILE} ]
then
	rm ${UPDATINGFLAGFILE}
	/usr/bin/perl ./process_updating.pl < ${FRESHPORTS_JAIL_BASE_DIR}/${PORTSDIR}/UPDATING
fi
