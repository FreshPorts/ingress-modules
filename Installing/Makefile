#
# $Id: Makefile,v 1.1.2.4 2005-01-23 00:27:37 dan Exp $
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

RUN_DEPENDS=	svscan:${PORTSDIR}/sysutils/daemontools \
				${SITE_PERL}/XML/Writer.pm::${PORTSDIR}/textproc/p5-XML-Writer \
				${SITE_PERL}/XML/Node.pm:${PORTSDIR}/textproc/p5-XML-Node \
				${SITE_PERL}/${PERL_ARCH}/DBD/Pg.pm:${PORTSDIR}/databases/p5-DBD-Pg \
				${SITE_PERL}/${PERL_ARCH}/DBI.pm:${PORTSDIR}/databases/p5-DBI \
				procmail:${PORTSDIR}/mail/procmail \
				${SITE_PERL}/Mail/Sender.pm:${PORTSDIR}/mail/p5-Mail-Sender \
				${PREFIX}/share/pear/HTML/Page2::${PORTSDIR}/devel/pear-HTML_Page2

NO_WRKSUBDIR=	YES
NO_BUILD=		YES
COMMENT=	NO COMMENT

do-install: 	# empty

.include <bsd.port.mk>




