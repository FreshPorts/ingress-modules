#!/bin/sh
#
# $Id: process_vuxml.sh,v 1.1.2.1 2004-10-03 02:20:15 dan Exp $
#
# Copyright (c) 2003-2004 DVL Software Limited
#
# Check to see if the switch is set, and if so, load the
# security/vuxml/vuln.xml file into the database
#
#  3-59/7  *   *   *   *  cd $DIR && ./process_vuxml.sh >> /dev/null
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

if [ "${VUXMLFLAGFILE}x" = 'x' -o "${PORTSDIR}x" = 'x' ]
then
	echo "please set VUXMLFLAGFILE and PORTSDIR in config.sh"
	exit 1
fi

if [ -r ${VUXMLFLAGFILE} ]
then
	rm ${VUXMLFLAGFILE}
	/usr/bin/perl ./process_vuxml.pl < ${PORTSDIR}/security/vuxml/vuln.xml
fi
