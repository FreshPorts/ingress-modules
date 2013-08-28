#!/bin/sh
#
# This extracts the DESCR, or filename of the description for this port.
#
# expected usage: sudo /usr/sbin/chroot -u USER JAIL /make-descr.sh PORTDIR
#
# where USER        - user as which to execute the commands.  e.g. dan
#       JAIL        - path to the jail created with the create-jail-directories.sh command. e.g. /usr/jail/FreshPorts
#       PORTDIR     - sysutils/bacula-server
#

. ./vars.sh

PORT=$1

cd ${PATHTOPORTS}/${PORT}

${MAKE} -V DESCR -f ${PATHTOPORTS}/${PORT}/Makefile \
        PORTSDIR=${PATHTOPORTS}            \
        LOCALBASE=${LOCALBASE}
