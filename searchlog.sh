#!/bin/sh
#
# $Id: searchlog.sh,v 1.3.2.2 2003-05-16 01:14:08 dan Exp $
#
# Copyright (c) 2001-2003 DVL Software
#

grep `date -v-1d "+%Y-%m-%d"` /usr/websites/freshports.org/dynamic/searchlog.txt
