#!/bin/sh
#
# $Id: freebsd-cvs.sh,v 1.7.2.1 2003-04-10 11:14:13 dan Exp $
#
# Copyright (c) 1999-2002 DVL Software
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

. config.sh

XML="${MSGDIR}/msgs/FreeBSD/xml"
OUTPUT="${MSGDIR}/msgs/FreeBSD/xml-output"

PATHNAME=$1
echo processing ${PATHNAME}

FILE=`basename ${PATHNAME}` 

#
# convert the raw file to XML
#
/usr/bin/perl ${SCRIPTDIR}/process_cvs_mail.pl < ${PATHNAME} >    \
       ${XML}/${FILE} 2>${XML}/${FILE}.errors
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

/usr/bin/perl ${SCRIPTDIR}/load_xml_into_db.pl $XML/$FILE > \
               ${OUTPUT}/$FILE 2>${OUTPUT}/$FILE.errors
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
