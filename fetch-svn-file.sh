#!/bin/sh
#
# $Id: fetch-svn-file.sh,v 1.3 2012-07-16 12:04:25 dan Exp $
#
# Copyright (c) 1999-2001 DVL Software
#
# This script used to fetch files from the cvs repo into our own tree.
#
#
# $Id: fetch-svn-file.sh,v 1.3 2012-07-16 12:04:25 dan Exp $
#
# Copyright (c) 2000-2004 DVL Software
#
echo "num of params = $#"
if  [ $# -ne 7 ];
	then echo error invoking script $0 : usage $0 URL DESTDIR SRCDIR FILE REVISION SUFFIX 1>&2
	exit 1
else
	URL=$1
	REPO=$2
	DESTDIR=$3
	SRCDIR=$4
	FILE=$5
	REVISION=$6
	SUFFIX=$7

	mkdir -p ${DESTDIR}
	if [ $? -ne 0 ]
	then
		exit 3
	fi

	FETCHFILE=$DESTDIR/$FILE

	# try to get around any possible caching by using a timestamp as a parameter
	#
	time=`/bin/date +"%s"`

	echo "* * * * *  about to fetch '$URL/$REPO/!svn/bc/$REVISION/head/$SRCDIR/$FILE?cache_busting_value=$time'"
	echo "* * * * *  fetching into $FETCHFILE"

    # fetch "http://svn.freebsd.org/ports/!svn/bc/300899/head/Makefile"
    # NOTE: SUFFIX is being ignored.  We always assume HEAD
	/usr/bin/fetch -A -o $FETCHFILE "$URL/$REPO/!svn/bc/$REVISION/head/$SRCDIR/$FILE?cache_busting_value=$time"
	exit $?
fi
