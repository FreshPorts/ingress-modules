#!/bin/sh
#
# $Id: archive-messages.sh,v 1.1.2.3 2003-05-10 19:44:29 dan Exp $
#
# Copyright (c) 2003 DVL Software Limited
#
# archive away all the messages which were created yesterday.
# this script is designed to be called like this from crontab:
#
#  10  0   *   *   *  cd $DIR && ./archive-messages.sh 1 >> /dev/null
#
# where $DIR is the directory in which this file exists.

if [ $# -ne 1 ]
then
   echo $0 : usage $0 DAYS
   exit 1
fi

if [ ! -f config.sh ]
then
	echo "config.sh not found..."
	exit 1
fi

. config.sh

DAYS=$1

BASEDIR=${MSGDIR}/msgs/FreeBSD

YYYY_MM_DD=`eval date -v-${DAYS}d "+%Y_%m_%d"`
YYYY_MM=`eval date -v-${DAYS}d "+%Y_%m"`
YYYYMMDD=`eval date -v-${DAYS}d "+%Y.%m.%d"`

mkdir -p ${BASEDIR}/archive/${YYYY_MM}/${YYYY_MM_DD}

SRC="${BASEDIR}/recent/${YYYYMMDD}*"
DEST="${BASEDIR}/archive/${YYYY_MM}/${YYYY_MM_DD}/"

echo ${SRC} ${DEST}
mv   ${SRC} ${DEST}
