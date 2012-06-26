#!/bin/sh
#
# $Id: process_vuxml.sh,v 1.5 2012-06-26 12:23:23 dan Exp $
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
	exit 1
fi

. config.sh

if [ $OFFLINE = 1 ]
then
	exit 0
fi

if [ "${VUXMLFLAGFILE}x" = 'x' -o "${PORTSDIR}x" = 'x' -o "${VUXMLMUTEX}x" = 'x' -o "${DIRLOG}x" = 'x' ]
then
	logger -t "FreshPorts ${0}" "please set all of VUXMLFLAGFILE, PORTSDIR, VUXMLMUTEX, and DIRLOG in config.sh"
	exit 1
fi

if [ -f ${VUXMLMUTEX} ]
then
	logger -t "FreshPorts ${0}"  "${VUXMLMUTEX} is set.  vuxml processing is already underway"
	exit 0
fi

if [ -r ${VUXMLFLAGFILE} ]
then
	touch ${VUXMLMUTEX}
	rm ${VUXMLFLAGFILE}
	logger -t "FreshPorts ${0}"  "vuxml processing begins"
	/usr/bin/perl ./process_vuxml.pl -w < ${PORTSDIR}/security/vuxml/vuln.xml > ${DIRLOG}/vuxml.log
	logger -t "FreshPorts ${0}"  "vuxml ident begins"
	/usr/bin/perl ./vuxml_ident.pl        ${PORTSDIR}/security/vuxml/vuln.xml > ${BASEDIR}/dynamic/vuxml_revision
	logger -t "FreshPorts ${0}"  "vuxml latest begins"
	/usr/bin/perl ./vuln_latest.pl
	rm ${VUXMLMUTEX}
	logger -t "FreshPorts ${0}"  "vuxml finishes"
else
	logger -t "FreshPorts ${0}"  "${VUXMLFLAGFILE} not set: no processing to do"
fi
logger -t "FreshPorts ${0}"  "vuxml terminates"
