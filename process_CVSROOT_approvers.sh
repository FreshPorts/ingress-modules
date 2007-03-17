#!/bin/sh
#
# $Id: process_CVSROOT_approvers.sh,v 1.3 2007-03-17 13:52:22 dan Exp $
#
# Copyright (c) 2003-2004 DVL Software Limited
#
if [ ! -f config.sh ]
then
	echo "config.sh not found..."
	exit 1
fi

. config.sh

if [ "${PORTSFREEZEFILE}x" = 'x' ]
then
	echo "please set PORTSFREEZEFILE in config.sh"
	exit 1
fi

if [ "${FRESHPORTS_FREEBSD_CVS_URL}x" = 'x' ]
then
	echo "please set FRESHPORTS_FREEBSD_CVS_URL in config.sh"
	exit 1
fi

#fetch -qo - http://www.freebsd.org/cgi/cvsweb.cgi/~checkout~/CVSROOT-ports/approvers | egrep -v -q '^#|^$'
echo about to fetch \
fetch -qo - "${FRESHPORTS_FREEBSD_CVS_URL}/~checkout~/CVSROOT-ports/approvers | egrep -v -q '^#|^$'
fetch -qo - "${FRESHPORTS_FREEBSD_CVS_URL}/~checkout~/CVSROOT-ports/approvers | egrep -v -q '^#|^$'
if [ $? = 0 ]
then
	touch ${PORTSFREEZEFILE}
else
	if [ -f ${PORTSFREEZEFILE} ]
	then
		rm ${PORTSFREEZEFILE}
	fi
fi
