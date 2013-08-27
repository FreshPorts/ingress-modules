#!/bin/sh
#
# This extracts the COMMENT, or category description, from a Category Makefile
#
# expected usage: sudo /usr/sbin/chroot -u USER JAIL /make-category-comment.sh CATEGORYDIR
#
# where USER        - user as which to execute the commands.  e.g. dan
#       JAIL        - path to the jail created with the create-jail-directories.sh command. e.g. /usr/jail/FreshPorts
#       CATEGORYDIR - sysutils
#

. ./vars.sh

CATEGORY=$1

cd ${PATHTOPORTS}/${CATEGORY}

${MAKE} -V COMMENT -f ${PATHTOPORTS}/${CATEGORY}/Makefile
