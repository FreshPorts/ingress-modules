#!/bin/sh

grep `date -v-1d "+%Y-%m-%d"` /www/freshports.org/searchlog.txt 
