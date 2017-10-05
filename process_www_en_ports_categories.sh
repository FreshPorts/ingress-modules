#!/bin/sh
#
# $Id: process_www_en_ports_categories.sh,v 1.4 2007-10-16 19:01:41 dan Exp $
#
# Copyright (c) 2003-2007 DVL Software Limited
#

logger -t FreshPorts $0 has been invoked

if [ ! -f /usr/local/etc/freshports/config.sh ]
then
	echo "/usr/local/etc/freshports/config.sh not found..."
	exit 1
fi

. /usr/local/etc/freshports/config.sh

if [ $OFFLINE = 1 ]
then
	logger -t FreshPorts system is OFFLINE ... exiting
	exit 0
fi

if [ "${WWWENPORTSCATEGORIES}x" = 'x' -o "${SPOOLINGDIR}x" = 'x' ]
then
	echo "please set WWWENPORTSCATEGORIES and SPOOLINGDIR in /usr/local/etc/freshports/config.sh"
	exit 1
fi

CATEGORIES="${SPOOLINGDIR}/categories"

if [ -r ${WWWENPORTSCATEGORIES} ]
then
	logger -t FreshPorts invoking categories_update_descriptions.pl with ${CATEGORIES}
	/usr/bin/perl categories_update_descriptions.pl ${CATEGORIES}

	# regardless of any errors, we should remove this as we don't want to keep doing this
	rm ${WWWENPORTSCATEGORIES}
else
	logger -t FreshPorts $0 was invoked but ${WWWENPORTSCATEGORIES} was not set.
fi
