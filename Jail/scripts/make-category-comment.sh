#!/bin/sh
#
# This extracts the COMMENT, or category description, from a Category Makefile
#
# expected usage: sudo /usr/sbin/chroot -u USER JAIL /make-category-comment.sh REPO_PATH CATEGORYDIR
#
# where USER        - user as which to execute the commands.  e.g. dan
#       JAIL        - path to the jail created with the create-jail-directories.sh command. e.g. /usr/jail/FreshPorts
#       REPO_PATH   - path to the SVN repository
#       CATEGORYDIR - sysutils
#

. ./vars.sh


REPO_PATH=$1
CATEGORY=$2

cd ${REPO_PATH}/${CATEGORY}

${MAKE} -V COMMENT -f ${REPO_PATH}/${CATEGORY}/Makefile
