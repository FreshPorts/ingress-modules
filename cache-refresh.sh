#!/bin/sh

if [ ! -f config.sh ]
then
	echo "config.sh not found..."
	exit 1
fi

. config.sh

if [ "${WEBSITEURL}x" = "x" ]
then
	echo 'define WEBSITEURL in config.sh first'
	exit 1
fi

/usr/bin/fetch -qo ${STAGINGDIR}/index.html ${WEBSITEURL}/caching-files/index.php
/usr/bin/fetch -qo ${STAGINGDIR}/news.rss   ${WEBSITEURL}/caching-files/news.php

/bin/chmod g+r ${STAGINGDIR}/*

/bin/mv ${STAGINGDIR}/* ${CACHEDIR}/
