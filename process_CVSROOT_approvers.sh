#!/bin/sh
#
# $Id: process_CVSROOT_approvers.sh,v 1.1.2.1 2004-09-17 03:13:01 dan Exp $
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

fetch -qo - http://www.freebsd.org/cgi/cvsweb.cgi/~checkout~/CVSROOT-ports/approvers | egrep -v -q '^#|^$'
if [ $? = 0 ]
then
	touch ${PORTSFREEZEFILE}
else
	rm ${PORTSFREEZEFILE}
fi
