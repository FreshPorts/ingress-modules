#!/bin/sh
#
# $Id: process_vuxml.sh,v 1.7 2012-07-24 15:56:40 dan Exp $
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

LOGFILE=${DIRLOG}/vuxml.log

if [ -r ${VUXMLFLAGFILE} ]
then
	touch ${VUXMLMUTEX}
	rm ${VUXMLFLAGFILE}
	logger -t   "FreshPorts ${0}"  "vuxml processing begins"
	echo `date` "FreshPorts ${0}"  "vuxml processing begins"                  >> ${LOGFILE}
	
	# define the vuln file we are going to operate on
	VULNFILE="${FRESHPORTS_JAIL_BASE_DIR}/${PORTSDIR}/security/vuxml/vuln.xml"
	
	/usr/local/bin/perl ./process_vuxml.pl < ${VULNFILE} >> ${LOGFILE}
	if [ $? -eq 0 ]
	then
	  logger -t "FreshPorts ${0}"  "process_vuxml.pl finishes normally"
	else
	  logger -t "FreshPorts ${0}"  "FATAL process_vuxml.pl finished with an error"
	fi

	logger -t "FreshPorts ${0}"  "vuxml ident begins on ${VULNFILE}"
	/usr/local/bin/perl ./vuxml_ident.pl     ${VULNFILE} > ${DYNAMICROOT}/vuxml_revision

	logger -t "FreshPorts ${0}"  "vuxml latest begins"
	/usr/local/bin/perl ./vuln_latest.pl
	if [ $? = 0 ]
	then
	  logger -t "FreshPorts ${0}"  "vuxml finishes normally"
	fi

	rm ${VUXMLMUTEX}
	echo `date` "FreshPorts ${0}"  "vuxml finishes" >> ${LOGFILE}
	logger -t "FreshPorts ${0}"  "vuxml finishes"
else
	logger -t "FreshPorts ${0}"  "${VUXMLFLAGFILE} not set: no processing to do"
fi
echo `date` "FreshPorts ${0}"  "vuxml terminates" >> ${LOGFILE}
logger -t "FreshPorts ${0}"  "vuxml terminates"
