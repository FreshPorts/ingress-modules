#!/bin/sh
#
# $Id: freebsd-cvs.sh,v 1.7 2002-02-24 02:37:35 dan Exp $
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

XML="msgs/FreeBSD/xml"
OUTPUT="msgs/FreeBSD/xml-output"

PATHNAME=$1
echo processing $PATHNAME

FILE=`basename $PATHNAME` 

/usr/bin/perl $HOME/scripts/process_cvs_mail.pl < $PATHNAME >    \
       $HOME/$XML/$FILE 2>$HOME/$XML/$FILE.errors
RESULT=$?

if [ -f $HOME/$XML/$FILE.errors ]
then
#  found errors
   if [  -s $HOME/$XML/$FILE.errors ]
   then
      exit 2
   else
      rm $HOME/$XML/$FILE.errors
   fi
fi

/usr/bin/perl $HOME/scripts/load_xml_into_db.pl $HOME/$XML/$FILE > \
               $HOME/$OUTPUT/$FILE 2>$HOME/$OUTPUT/$FILE.errors
RESULT=$?

if [ -f $HOME/$OUTPUT/$FILE.errors ]
then
#  found errors
   if [  -s $HOME/$OUTPUT/$FILE.errors ]
   then
      if [ $RESULT -eq 2 ] || [ $RESULT -eq 4 ]
      then
#         rm $HOME/$OUTPUT/$FILE.errors
      else
         exit 0
      fi
   else
      rm $HOME/$OUTPUT/$FILE.errors
   fi
fi
