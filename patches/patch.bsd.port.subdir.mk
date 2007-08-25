Index: bsd.port.subdir.mk
===================================================================
RCS file: /home/FreeBSD/pcvs/ports/Mk/bsd.port.subdir.mk,v
retrieving revision 1.60
diff -u -r1.60 bsd.port.subdir.mk
--- bsd.port.subdir.mk	28 Feb 2005 21:09:04 -0000	1.60
+++ bsd.port.subdir.mk	7 Mar 2005 01:30:20 -0000
@@ -33,7 +33,7 @@
 #	configure, deinstall,
 #	depend, depends, describe, extract, fetch, fetch-list, ignorelist,
 #	install, maintainer, makesum, package, readmes, realinstall, reinstall,
-#	tags
+#	status, tags
 #
 #	search:
 #		Search for ports using either 'make search key=<keyword>'
@@ -109,6 +109,7 @@
 TARGETS+=	package
 TARGETS+=	realinstall
 TARGETS+=	reinstall
+TARGETS+=	status
 TARGETS+=	tags
 
 .for __target in ${TARGETS}
