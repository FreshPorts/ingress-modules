#!/bin/sh
#
# $Id: archive-messages.sh,v 1.1.2.1 2003-02-25 14:13:27 dan Exp $
#
# Copyright (c) 2001 DVL Software Limited
#
# archive away all the messages which were created yesterday.
# this script is designed to be called like this from crontab:
#
#  10  0   *   *   *  archive-messages.sh 1
#

if [ $# -ne 1 ]
then
   echo $0 : usage $0 DAYS
   exit 1
fi


DAYS=$1

BASEDIR=${HOME}/msgs/FreeBSD
SCRIPTDIR=${HOME}/scripts

${SCRIPTDIR}/archive-logs.sh ${DAYS} ${BASEDIR}/raw        ${BASEDIR}/archive/raw
${SCRIPTDIR}/archive-logs.sh ${DAYS} ${BASEDIR}/xml        ${BASEDIR}/archive/xml
${SCRIPTDIR}/archive-logs.sh ${DAYS} ${BASEDIR}/xml-output ${BASEDIR}/archive/xml-output
