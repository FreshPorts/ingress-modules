#!/bin/sh
#
# $Id: searchlog.sh,v 1.3 2002-01-06 07:17:55 dan Exp $
#
# Copyright (c) 2001 DVL Software
#

grep `date -v-1d "+%Y-%m-%d"` ${HOME}/src/configuration/searchlog.txt
