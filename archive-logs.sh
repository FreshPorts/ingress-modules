#!/bin/sh
#
# $Id: archive-logs.sh,v 1.4 2001-12-22 23:23:08 dan Exp $
#
# Copyright (c) 2001 DVL Software Limited
#
# archive away all the messages which were created N days ago
# take them from MSGDIR and put them in ARCHIVEDIR/YYYY_MM/YYYY_MM_DD/
#

if [ $# -ne 3 ]
then
   echo $0 : usage $0 DAYS MSGDIR ARCHIVEDIR
   exit 1
fi


ARCHIVEDIR=$3
MSGDIR=$2

YYYY_MM_DD=`eval date -v-$1d "+%Y_%m_%d"`
YYYY_MM=`eval date -v-$1d "+%Y_%m"`
YYYYMMDD=`eval date -v-$1d "+%Y.%m.%d"`

mkdir -p ${ARCHIVEDIR}/${YYYY_MM}/${YYYY_MM_DD}

SRC="${MSGDIR}/${YYYYMMDD}*"
DEST="${ARCHIVEDIR}/${YYYY_MM}/${YYYY_MM_DD}/"

echo ${SRC} ${DEST}
mv   ${SRC} ${DEST}
