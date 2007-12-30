#!/bin/sh

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

MASTER='sysutils/bacula-server'

cd ${PORTSDIR}/sysutils/bacula-client
COMMAND="make -V MASTER_PORT PORTSDIR=${PORTSDIR} LOCALBASE=/nonexistentlocal X11BASE=/nonexistentx"
MASTER_PORT=`${COMMAND}`

if [ "${MASTER_PORT}X" != "${MASTER}X" ]
then
	echo "make -V MASTER_PORT on sysutils/bacula-client does not give '${MASTER}'" | mail -s "FAILED: MASTER_PORT" ${ADMINEMAIL}
fi
