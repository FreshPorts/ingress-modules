#!/bin/sh
#
# $Id: archive-messages.sh,v 1.1 2001-12-22 23:23:08 dan Exp $
#
# Copyright (c) 2001 DVL Software Limited
#
# archive away all the messages which were created yesterday.
# this script is designed to be called like this from crontab:
#
#  10  0   *   *   *  archive-messages.sh
#

BASEDIR=${HOME}/msgs/FreeBSD
SCRIPTDIR=${HOME}/scripts

${SCRIPTDIR}/archive-logs.sh 1 ${BASEDIR}/raw        ${BASEDIR}/archive/raw
${SCRIPTDIR}/archive-logs.sh 1 ${BASEDIR}/xml        ${BASEDIR}/archive/xml
${SCRIPTDIR}/archive-logs.sh 1 ${BASEDIR}/xml-output ${BASEDIR}/archive/xml-output
