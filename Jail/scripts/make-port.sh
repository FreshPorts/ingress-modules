#!/bin/sh
#
# This extracts information from a port Makefile
#
# expected usage: sudo /usr/sbin/chroot -u USER JAIL /make-port.sh PORTDIR
#
# where USER    - user as which to execute the commands.  e.g. dan
#       JAIL    - path to the jail created with the create-jail-directories.sh command. e.g. /usr/jail/FreshPorts
#       PORTDIR - sysutils/bacula-server
#

. ./vars.sh

PORT=$1

cd ${PATHTOPORTS}/${PORT}

${MAKE} -V PORTNAME    -V PKGNAME        -V DESCR           -V CATEGORIES     -V PORTVERSION    -V PORTREVISION  \
        -V COMMENT     -V COMMENTFILE    -V MAINTAINER      -V EXTRACT_SUFX   -V BUILD_DEPENDS  -V RUN_DEPENDS   \
        -V LIB_DEPENDS -V FORBIDDEN      -V BROKEN          -V DEPRECATED     -V IGNORE         -V MASTER_PORT   \
        -V LATEST_LINK -V NO_LATEST_LINK -V NO_PACKAGE      -V PKGNAMEPREFIX  -V PKGNAMESUFFIX  -V PORTEPOCH     \
        -V RESTRICTED  -V NO_CDROM       -V EXPIRATION_DATE -V IS_INTERACTIVE -V ONLY_FOR_ARCHS -V NOT_FOR_ARCHS \
        -V LICENSE \
        -f ${PATHTOPORTS}/${PORT}/Makefile \
        PORTSDIR=${PATHTOPORTS}            \
        LOCALBASE=${LOCALBASE}
