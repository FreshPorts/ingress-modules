#!/bin/sh
#
# $Id: create_dirs.sh,v 1.1.2.3 2003-04-10 11:44:36 dan Exp $
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

mkdir -p $BASEDIRECTORY/mail
mkdir -p $BASEDIRECTORY/msgs
mkdir -p $BASEDIRECTORY/msgs/spooling
mkdir -p $BASEDIRECTORY/msgs/FreeBSD
mkdir -p $BASEDIRECTORY/msgs/FreeBSD/archive
mkdir -p $BASEDIRECTORY/msgs/FreeBSD/incoming
mkdir -p $BASEDIRECTORY/msgs/FreeBSD/raw
mkdir -p $BASEDIRECTORY/msgs/FreeBSD/retry
mkdir -p $BASEDIRECTORY/msgs/FreeBSD/xml
mkdir -p $BASEDIRECTORY/msgs/FreeBSD/xml-output
