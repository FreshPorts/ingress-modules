#!/bin/sh
#
# postgresql database backup
# Copyright 1999, 2000 DVL Software Limited
#

#
# the name of the backup file. file name format is 
# freshports.backup.2000.01.12.at.22.59.48.tgz
#
WorkingDirectory=$HOME
BackupFile="freshports.backup.`date +%Y.%m.%d.at.%H.%M.%S`.tgz"
TempFreshportsFile="freshports.backup.txt"
TempFreshportsForumFile="freshports.phorum.backup.txt"
TempFreshportsSurveyFile="freshports.survey.backup.txt"

#
# dump the database.
# make the following replacements:
#
#     userid     - the user id to use when connecting to the database
#     password   - the password for the above user
#     database   - the name of database to dump
#     /pathto/   - the path to the backup file
#
/usr/local/bin/pg_dump FreshPorts2 > $WorkingDirectory$TempFreshportsFile
#
# compress it
#
zip -9 $BackupFile $WorkingDirectory$TempFreshportsFile

#
# copy it offsite
#

/usr/bin/scp -P 2222 $BackupFile dan@diary.unixathome.org:$BackupFile

#
# remove the files we created
#
rm $BackupFile $WorkingDirectory$TempFreshportsFile $WorkingDirectory$TempFreshportsForumFile $WorkingDirectory$TempFreshportsSurveyFile
