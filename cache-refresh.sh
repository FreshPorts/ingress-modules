#!/bin/sh
#
# $Id: cache-refresh.sh,v 1.1.2.11 2006-07-15 03:29:57 dan Exp $
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

if [ "${SPOOLINGDIR}x" = "x" ]
then
	echo 'define SPOOLINGDIR in config.sh first'
	exit 1
fi

if [ "${CACHE_NEEDS_REFRESH}x" = 'x' ]
then
	echo "please set CACHE_NEEDS_REFRESH in config.sh"
	exit 1
fi

if [ -r ${CACHE_NEEDS_REFRESH} ]
then
	#
	# remove the flag
	#
	/bin/rm "${CACHE_NEEDS_REFRESH}"

	#
	# the following remove the old news feeds
	#
	/bin/rm -f "${NEWSCACHEDIR}/*.xml"

	${FETCH} ${FETCH_OPTIONS} ${SPOOLINGDIR}/index.html      ${WEBSITEURL}caching-files/index.php?numcommits=10
	${FETCH} ${FETCH_OPTIONS} ${SPOOLINGDIR}/commits.html    ${WEBSITEURL}caching-files/index.php?numcommits=100
	${FETCH} ${FETCH_OPTIONS} ${SPOOLINGDIR}/news.rss        ${WEBSITEURL}caching-files/news.php
	${FETCH} ${FETCH_OPTIONS} ${SPOOLINGDIR}/ports-new.rss   ${WEBSITEURL}caching-files/ports-new.php

	${FETCH} ${FETCH_OPTIONS} ${SPOOLINGDIR}/categories-by-category.html    ${WEBSITEURL}caching-files/categories.php?sort=category
	${FETCH} ${FETCH_OPTIONS} ${SPOOLINGDIR}/categories-by-count.html       ${WEBSITEURL}caching-files/categories.php?sort=count
	${FETCH} ${FETCH_OPTIONS} ${SPOOLINGDIR}/categories-by-description.html ${WEBSITEURL}caching-files/categories.php?sort=description
	${FETCH} ${FETCH_OPTIONS} ${SPOOLINGDIR}/categories-by-lastupdate.html  ${WEBSITEURL}caching-files/categories.php?sort=lastupdate

	#
	# because of these wild cards, we need to have exclusive use of SPOOLINGDIR
	#
	/bin/chmod g+r ${SPOOLINGDIR}/*

	/bin/mv ${SPOOLINGDIR}/* ${CACHEDIR}/
fi
