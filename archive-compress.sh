#!/bin/sh

#if [ $# -ne 1 ]
#then
#   echo $0 : usage $0 YYYY_MM 1>&2
#   exit 1
#fi

YYYY_MM=`date -v1d  -v-1d "+%Y_%m"`

ARCHIVEDIR="/usr/local/etc/freshports/msgs/archives"

#
# we do a cd so as not to include the whole path in the tarball
#
cd $ARCHIVEDIR
tar cfz ${YYYY_MM}.tgz ${YYYY_MM}/* 
if [ $? -ne 0 ]
then
  echo tar failed
  exit
fi

rm -rf $ARCHIVEDIR/${YYYY_MM}
