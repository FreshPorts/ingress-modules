#!/bin/sh
#
# $Id: process_vuxml.sh,v 1.1.2.4 2005-01-03 21:35:48 dan Exp $
#
# Copyright (c) 2003-2005 DVL Software Limited
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

if [ $OFFLINE = 1 ]
then
	exit 0
fi

if [ "${VUXMLFLAGFILE}x" = 'x' -o "${PORTSDIR}x" = 'x' ]
then
	echo "please set VUXMLFLAGFILE and PORTSDIR in config.sh"
	exit 1
fi

if [ -r ${VUXMLFLAGFILE} ]
then
	rm ${VUXMLFLAGFILE}
	/usr/bin/perl ./process_vuxml.pl -w < ${PORTSDIR}/security/vuxml/vuln.xml
	/usr/bin/perl ./vuxml_ident.pl      < ${PORTSDIR}/security/vuxml/vuln.xml > ${BASEDIR}/dynamic/vuxml_revision
fi
