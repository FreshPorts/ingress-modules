#!/bin/sh

grep `date -v-1d "+%Y-%m-%d"` /home/freshports.org/logs/searchlog.txt
