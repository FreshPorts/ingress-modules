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

# we don't need this any more.
# But it did help to find the pre-everything bugs
# see also 3BB8479C.16045.406FAE31@localhost
# in the freebsd mailing list archives.
#
#      mkdir /usr/ports/${CATEG}/${PORT}/pkg
#      if [ $? -ne 0 ]
#      then
#         exit 2
#      fi
   fi
 fi

 FETCHFILE=/usr/ports/$CATEG/$PORT/$FILE

 echo about to fetch http://www.freebsd.org/cgi/cvsweb.cgi/~checkout~/ports/$CATEG/$PORT/$FILE?rev=HEAD
 echo fetching into $FETCHFILE

# wget --user-agent=Lynx -O $FETCHFILE http://www.freebsd.org/cgi/cvsweb.cgi/~checkout~/ports/$CATEG/$PORT/$FILE?rev=HEAD
# fetch -o $FETCHFILE http://www.freebsd.org/cgi/cvsweb.cgi/~checkout~/ports/$CATEG/$PORT/$FILE?rev=HEAD
#/usr/local/bin/lynx -source -dump http://www.freebsd.org/cgi/cvsweb.cgi/~checkout~/ports/$CATEG/$PORT/$FILE?rev=HEAD > $FETCHFILE

#
# try to get around any possible caching by using a timestamp as a parameter
#
time=`/bin/date +"%s"`

/usr/local/bin/lynx -source -dump http://www.freebsd.org/cgi/cvsweb.cgi/ports/$CATEG/$PORT/$FILE?rev=HEAD\&abcd=$time > $FETCHFILE
 if [ $? -ne 0 ]
 then
    exit 6
 fi

 RESULT=0

 #
 # this is an attempt to ensure we have the correction owner
 #
# I don't think this is needed just here..
# /usr/sbin/chown daemon:daemon $FETCHFILE
 exit $RESULT
fi

