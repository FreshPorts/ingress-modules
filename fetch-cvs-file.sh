#!/bin/sh
#
# $Id: fetch-cvs-file.sh,v 1.6.2.6 2003-05-16 01:14:03 dan Exp $
#
# Copyright (c) 2000-2003 DVL Software
#

if  [ $# -ne 4 ];
	then echo $0 : usage $0 DESTDIR SRCDIR FILE REVISION 1>&2
	exit 1
else
	DESTDIR=$1
	SRCDIR=$2
	FILE=$3
	REVISION=$4

	mkdir -p ${DESTDIR}
	if [ $? -ne 0 ]
	then
		exit 3
	fi

	FETCHFILE=$DESTDIR/$FILE

#	echo about to fetch http://www.freebsd.org/cgi/cvsweb.cgi/~checkout~/$SRCDIR/$FILE?rev=REVISION
#	echo fetching into $FETCHFILE

	# try to get around any possible caching by using a timestamp as a parameter
	#
	time=`/bin/date +"%s"`

	/usr/bin/fetch -A -o $FETCHFILE http://www.freebsd.org/cgi/cvsweb.cgi/$SRCDIR/$FILE?rev=$REVISION\&cache_busting_value=$time
	exit $?
fi
