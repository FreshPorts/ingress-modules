#!/bin/sh

if  [ $# -ne 3 ];
   then echo $0 : usage $0 CATEG PORT FILE 1>&2
   exit 1
else
   CATEG=$1
   PORT=$2
   FILE=$3

   if [ ! -d /usr/ports/${CATEG} ]
   then
      echo about to create /usr/ports/${CATEG}
      mkdir /usr/ports/${CATEG}
      if [ $? -ne 0 ]
      then
         exit 5
      fi
   fi

   if [ ! -d /usr/ports/${CATEG}/${PORT} ]
   then
      echo about to create /usr/ports/${CATEG}/${PORT}
      mkdir /usr/ports/${CATEG}/${PORT}
      if [ $? -ne 0 ]
      then
         exit 3
      fi

      mkdir /usr/ports/${CATEG}/${PORT}/pkg
      if [ $? -ne 0 ]
      then
         exit 2
      fi
   fi
 fi

 FETCHFILE=/usr/ports/$CATEG/$PORT/$FILE

 echo about to fetch http://www.freebsd.org/cgi/cvsweb.cgi/ports/$CATEG/$PORT/$FILE

 fetch -b -o $FETCHFILE http://www.freebsd.org/cgi/cvsweb.cgi/ports/$CATEG/$PORT/$FILE?rev=HEAD
 if [ $? -ne 0 ]
 then
    exit 6
 fi

 #
 # this is an attempt to ensure we have the correction owner
 #
 /usr/sbin/chown daemon:daemon $FETCHFILE
 exit $?
fi

