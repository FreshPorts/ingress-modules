#!/bin/sh
#
# $Id: newusers.sh,v 1.2.2.1 2003-05-16 01:14:05 dan Exp $
#
# Copyright (c) 2001-2003 DVL Software
#
/usr/bin/perl newusers.pl `date -v-1d "+%Y-%m-%d"` `date -v-1d "+%Y-%m-%d"`
