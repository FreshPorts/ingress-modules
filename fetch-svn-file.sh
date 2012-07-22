#!/bin/sh
#
# $Id: fetch-svn-file.sh,v 1.4 2012-07-22 12:05:51 dan Exp $
#
# Copyright (c) 1999-2001 DVL Software
#
# This script used to fetch files from the cvs repo into our own tree.
#
#
# $Id: fetch-svn-file.sh,v 1.4 2012-07-22 12:05:51 dan Exp $
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

	# let's try using svn cat here..
    echo "svn cat ${URL}/${REPO}/head/${SRCDIR}/${FILE}@${REVISION} > ${FETCHFILE}"
	echo "* * * * *  fetching into $FETCHFILE"

    svn cat ${URL}/${REPO}/head/${SRCDIR}/${FILE}@${REVISION} > ${FETCHFILE}
	exit $?
fi
