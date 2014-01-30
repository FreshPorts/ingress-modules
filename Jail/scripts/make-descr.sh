#!/bin/sh
#
# This extracts the DESCR, or filename of the description for this port.
#
# expected usage: sudo /usr/sbin/chroot -u USER JAIL /make-descr.sh REPO_PATH PORTDIR
#
# where USER        - user as which to execute the commands.  e.g. dan
#       JAIL        - path to the jail created with the create-jail-directories.sh command. e.g. /usr/jail/FreshPorts
#       REPO_PATH   - path to the SVN repository
#       PORTDIR     - sysutils/bacula-server
#

. ./vars.sh

REPO_PATH=$1
PORT=$2

cd ${REPO_PATH}/${PORT}

${MAKE} -V DESCR -f ${REPO_PATH}/${PORT}/Makefile \
        PORTSDIR=${REPO_PATH}            \
        LOCALBASE=${LOCALBASE}
