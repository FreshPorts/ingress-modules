#!/bin/sh

if [ $# -ne 1 ]
then
   echo $0 : usage $0 DAYS 1>&2
   exit 1
fi



DATE="date -v-${1}d \"+%Y%m%d\""

echo $DATE

ARCHIVEDIR="/usr/local/etc/freshports/msgs/archives"
MSGDIR="/usr/local/etc/freshports/msgs"
YYYY_MM_DD=`eval date -v-$1d "+%Y_%m_%d"`
YYYY_MM=`eval date -v-$1d "+%Y_%m"`
YYYYMMDD=`eval date -v-$1d "+%Y%m%d"`

#
# create the archive directory
#
if [ ! -d ${ARCHIVEDIR} ]
then
  echo creating ${ARCHIVEDIR}
  mkdir ${ARCHIVEDIR}
fi

#
# create the directory for the month in question
#
if [ ! -d ${ARCHIVEDIR}/${YYYY_MM} ]
then
  echo creating ${ARCHIVEDIR}/${YYYY_MM}
  mkdir ${ARCHIVEDIR}/${YYYY_MM}
fi

#
# create the directory for the day in question
#
if [ ! -d ${ARCHIVEDIR}/${YYYY_MM}/${YYYY_MM_DD} ]
then
  echo creating ${ARCHIVEDIR}/${YYYY_MM}/${YYYY_MM_DD}
  mkdir ${ARCHIVEDIR}/${YYYY_MM}/${YYYY_MM_DD}
fi

#
# move everything to where it should be
#
#if [ -f ${MSGDIR}/${YYYYMMDD}* ];
#then
   echo moving
   mv ${MSGDIR}/${YYYYMMDD}* ${ARCHIVEDIR}/${YYYY_MM}/${YYYY_MM_DD}/
#fi

