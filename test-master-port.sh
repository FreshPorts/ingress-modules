#!/bin/sh

if [ ! -f /usr/local/etc/freshports/config.sh ]
then
	echo "/usr/local/etc/freshports/config.sh not found..."
	exit 1
fi

. /usr/local/etc/freshports/config.sh

if [ $OFFLINE = 1 ]
then
	exit 0
fi

MASTER='sysutils/bacula-server'

# this always tests against head
COMMAND="/usr/local/bin/sudo /usr/sbin/chroot -u ${FRESHPORTS_JAIL_USER} ${FRESHPORTS_JAIL_BASE_DIR} ${FRESHPORTS_JAIL_MASTER_PORT_SCRIPT} ${PORTSDIR} sysutils/bacula-client"
MASTER_PORT=`${COMMAND}`

if [ "${MASTER_PORT}X" != "${MASTER}X" ]
then
	echo "make -V MASTER_PORT on sysutils/bacula-client does not give '${MASTER}'\nInstead, it gives '${MASTER_PORT}'." | mail -s "FAILED: MASTER_PORT" ${ADMINEMAIL}
fi
