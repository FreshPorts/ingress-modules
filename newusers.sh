#!/bin/sh
#
# $Id: newusers.sh,v 1.2 2002-01-06 07:17:18 dan Exp $
#
# Copyright (c) 2001 DVL Software
#
/usr/bin/perl newusers.pl `date -v-1d "+%Y-%m-%d"` `date -v-1d "+%Y-%m-%d"`
