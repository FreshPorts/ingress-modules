#
# $Id: Makefile,v 1.1.2.1 2002-03-22 21:54:43 dan Exp $
#
# Install the ports needed by FreshPorts
#
# Copyright (c) 2002 DVL Software Limited

PORTNAME=		FreshPorts-ports
PORTVERSION=	1.0
CATEGORIES=		misc

MASTER_SITES=   # none
DISTFILES=      # none

MAINTAINER=		ports@freebsddiary.org

RUN_DEPENDS=	daemontools:${PORTSDIR}/sysutils/daemontools \
				XML-Writer:${PORTSDIR}/textproc/p5-XML-Writer \
				XML-Node:${PORTSDIR}/textproc/p5-XML-Node \
				DBD-Pg:${PORTSDIR}/databases/p5-DBD-Pg \
				DBI:${PORTSDIR}/databases/p5-DBI \
				procmail:${PORTSDIR}/mail/procmail

NO_WRKSUBDIR=	YES
NO_BUILD=		YES

do-install: 	# empty

.include <bsd.port.mk>




