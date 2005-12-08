#!/bin/sh
#
# $Id: cache-refresh.sh,v 1.1.2.9 2005-12-08 04:59:43 dan Exp $
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

if [ "${STAGINGDIR}x" = "x" ]
then
	echo 'define STAGINGDIR in config.sh first'
	exit 1
fi

if [ "${CACHE_NEEDS_REFRESH}x" = 'x' ]
then
	echo "please set CACHE_NEEDS_REFRESH in config.sh"
	exit 1
fi

if [ -r ${CACHE_NEEDS_REFRESH} ]
then
	rm ${CACHE_NEEDS_REFRESH}
	${FETCH} ${FETCH_OPTIONS} ${STAGINGDIR}/index.html      ${WEBSITEURL}caching-files/index.php?numcommits=10
	${FETCH} ${FETCH_OPTIONS} ${STAGINGDIR}/commits.html    ${WEBSITEURL}caching-files/index.php?numcommits=100
	${FETCH} ${FETCH_OPTIONS} ${STAGINGDIR}/news.rss        ${WEBSITEURL}caching-files/news.php
	${FETCH} ${FETCH_OPTIONS} ${STAGINGDIR}/ports-new.rss   ${WEBSITEURL}caching-files/ports-new.php

	${FETCH} ${FETCH_OPTIONS} ${STAGINGDIR}/categories-by-category.html    ${WEBSITEURL}caching-files/categories.php?sort=category
	${FETCH} ${FETCH_OPTIONS} ${STAGINGDIR}/categories-by-count.html       ${WEBSITEURL}caching-files/categories.php?sort=count
	${FETCH} ${FETCH_OPTIONS} ${STAGINGDIR}/categories-by-description.html ${WEBSITEURL}caching-files/categories.php?sort=description
	${FETCH} ${FETCH_OPTIONS} ${STAGINGDIR}/categories-by-lastupdate.html  ${WEBSITEURL}caching-files/categories.php?sort=lastupdate

	/bin/chmod g+r ${STAGINGDIR}/*

	/bin/mv ${STAGINGDIR}/* ${CACHEDIR}/
fi
