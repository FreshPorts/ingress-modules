#!/bin/sh
#
# This extracts the master port for a given port.
#
# sudo /usr/sbin/chroot -u USER JAIL /make-master-port-test.sh sysutils/bacula-client
#
# where USER    - user as which to execute the commands.  e.g. dan
#       JAIL    - path to the jail created with the create-jail-directories.sh command. e.g. /usr/jail/FreshPorts
#       PORTDIR - sysutils/bacula-server
#

. ./vars.sh

PORT=$1

cd ${PATHTOPORTS}/${PORT}

${MAKE} master-sites-all PORTSDIR=${PATHTOPORTS} LOCALBASE=${LOCALBASE} -f ${PATHTOPORTS}/${PORT}/Makefile
