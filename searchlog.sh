#!/bin/sh
#
# $Id: searchlog.sh,v 1.3.2.1 2002-06-02 14:03:28 dan Exp $
#
# Copyright (c) 2001-2002 DVL Software
#

grep `date -v-1d "+%Y-%m-%d"` /usr/websites/freshports.org/dynamic/searchlog.txt
