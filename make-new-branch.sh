#!/bin/sh

if [ $# -ne 1 ]
then
   echo $0 : usage $0 BRANCH-NAME-AS-FOUND-IN-SVN
   exit 1
fi

if [ ! -f /usr/local/etc/freshports/config.sh ]
then
	echo "/usr/local/etc/freshports/config.sh not found..."
	exit 1
fi

. /usr/local/etc/freshports/config.sh

echo ${FRESHPORTS_JAIL_BASE_DIR}${PORTSDIRBASE}
cd ${FRESHPORTS_JAIL_BASE_DIR}${PORTSDIRBASE}
mkdir "PORTS-$1"
svn co svn://svn.freebsd.org/ports/branches/$1 "PORTS-$1"
