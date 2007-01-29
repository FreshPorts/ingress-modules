#!/bin/sh
#
# $Id: process_www_en_ports_categories.sh,v 1.1 2007-01-29 00:17:35 dan Exp $
#
# Copyright (c) 2003-2007 DVL Software Limited
#
# Check to see if the switch is set, and if so, load the
# /usr/ports/MOVED file into the database
#
#  3-59/7  *   *   *   *  cd $DIR && ./process_moved.sh >> /dev/null
#
# where $DIR is the directory in which this file exists.
#
# file switch, set by commit processing script
# That file 

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

if [ "${WWWENPORTSCATEGORIES}x" = 'x' -o "${SPOOLINGDIR}x" = 'x' ]
then
	echo "please set WWWENPORTSCATEGORIES and SPOOLINGDIR in config.sh"
	exit 1
fi

CATEGORIES="${SPOOLINGDIR}/categories"

if [ -r ${WWWENPORTSCATEGORIES} ]
then
	fetch -q -o ${CATEGORIES} "http://www.freebsd.org/cgi/cvsweb.cgi/~checkout~/www/en/ports/categories?rev=HEAD&content-type=text/plain"
	if [ $? = 0 ]
	then
		/usr/bin/perl categories_update_descriptions.pl ${CATEGORIES}
	else
		logger -t FreshPorts $0 could not fetch the categories file
	fi

	# regardless of any errors, we should remove this as we don't want to keep doing this
	rm ${WWWENPORTSCATEGORIES}
else
	logger -t FreshPorts $0 was invoked but ${WWWENPORTSCATEGORIES} was not set.
fi
