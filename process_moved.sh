#!/bin/sh
#
# $Id: process_moved.sh,v 1.1.2.3 2004-10-12 00:45:28 dan Exp $
#
# Copyright (c) 2003-2004 DVL Software Limited
#
# Check to see if the switch is set, and if so, load the
# /usr/ports/MOVED file into the database
#
#  3-59/7  *   *   *   *  cd $DIR && ./process_moved.sh >> /dev/null
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

if [ "${MOVEDFLAGFILE}x" = 'x' -o "${PORTSDIR}x" = 'x' ]
then
	echo "please set MOVEDFLAGFILE and PORTSDIR in config.sh"
	exit 1
fi

if [ -r ${MOVEDFLAGFILE} ]
then
	rm ${MOVEDFLAGFILE}
	/usr/bin/perl ./process_moved.pl < ${PORTSDIR}/MOVED
fi
