#!/bin/sh
#
# $Id: create_dirs.sh,v 1.3 2006-12-17 12:04:07 dan Exp $
#
# Copyright (c) 1999-2002 DVL Software
#
# use this script to create the directories needed by the ~/scripts/procmail/dot.procmailrc
# script and ~/scripts/config.sh
#

if [ $# -ne 1 ]
then
   echo $0 : usage $0 BASEDIRECTORY
   exit 1
fi

BASEDIRECTORY=$1

mkdir -p $BASEDIRECTORY/msgs
mkdir -p $BASEDIRECTORY/msgs/FreeBSD
mkdir -p $BASEDIRECTORY/msgs/FreeBSD/archive
mkdir -p $BASEDIRECTORY/msgs/FreeBSD/incoming
mkdir -p $BASEDIRECTORY/msgs/FreeBSD/recent
mkdir -p $BASEDIRECTORY/msgs/FreeBSD/retry
mkdir -p $BASEDIRECTORY/msgs/FreeBSD/spooling
