#!/bin/sh
#
# $Id: freebsd-cvs.sh,v 1.7.2.6 2004-10-12 00:45:28 dan Exp $
#
# Copyright (c) 1999-2003 DVL Software
#
# Process a raw mail message by converting it to XML, then importing it into
# the database.
#
# Takes a file name as a parameter
#

if [ $# -ne 1 ]
then
   echo $0 : usage $0 FILE
   exit 1
fi

if [ ! -f config.sh ]
then
	echo "config.sh not found..."
	exit 1
fi

. config.sh

if [ $OFFLINE = 1 ]
then
	exit 0
fi

XML="${MSGDIR}/msgs/FreeBSD/recent"
OUTPUT="${MSGDIR}/msgs/FreeBSD/recent"

PATHNAME=$1

FILE=`basename ${PATHNAME}` 

#
# convert the raw file to XML
#
/usr/bin/perl ${SCRIPTDIR}/process_cvs_mail.pl < ${PATHNAME} >    \
       ${XML}/${FILE}.xml 2>${XML}/${FILE}.errors
RESULT=$?

if [ -f ${XML}/${FILE}.errors ]
then
#  found errors
   if [  -s $XML/$FILE.errors ]
   then
      exit 2
   else
      rm $XML/$FILE.errors
   fi
fi

#
# load the XML into the database
#

/usr/bin/perl ${SCRIPTDIR}/load_xml_into_db.pl ${XML}/${FILE}.xml > \
               ${OUTPUT}/${FILE}.loading 2>${OUTPUT}/$FILE.errors
RESULT=$?

if [ -f ${OUTPUT}/$FILE.errors ]
then
#  found errors
   if [  -s ${OUTPUT}/$FILE.errors ]
   then
      if [ $RESULT -eq 2 ] || [ $RESULT -eq 4 ]
      then
#         rm ${OUTPUT}/$FILE.errors
      else
         exit 0
      fi
   else
      rm ${OUTPUT}/$FILE.errors
   fi
fi
