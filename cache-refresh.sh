#!/bin/sh
#
# $Id: cache-refresh.sh,v 1.1.2.6 2005-01-13 22:37:50 dan Exp $
#
# Copyright (c) 2004 DVL Software Limited
#

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

if [ "${WEBSITEURL}x" = "x" ]
then
	echo 'define WEBSITEURL in config.sh first'
	exit 1
fi

/usr/bin/fetch -qo ${STAGINGDIR}/index.html   ${WEBSITEURL}caching-files/index.php?numcommits=10
/usr/bin/fetch -qo ${STAGINGDIR}/commits.html ${WEBSITEURL}caching-files/index.php?numcommits=100
/usr/bin/fetch -qo ${STAGINGDIR}/news.rss     ${WEBSITEURL}caching-files/news.php

/bin/chmod g+r ${STAGINGDIR}/*

/bin/mv ${STAGINGDIR}/* ${CACHEDIR}/
