#!/bin/sh

. config.sh

MASTER='sysutils/bacula-server'

cd ${PORTSDIR}/sysutils/bacula-client
COMMAND="make -V MASTERPORT PORTSDIR=${PORTSDIR} LOCALBASE=/nonexistentlocal X11BASE=/nonexistentx"
MASTERPORT=`${COMMAND}`

if [ "${MASTERPORT}X" != "${MASTER}X" ]
then
	echo "make -V MASTERPORT on sysutils/bacula-client does not give '${MASTER}'" | mail -s "FAILED: MASTERPORT" ${ADMINEMAIL}
fi