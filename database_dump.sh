#!/bin/sh

#
# mysql databse backup
# Copyright 1999, 2000 DVL Software Limited
#
# Available from http://www.freebsddiary.org/samples/database_dump.sh.txt
#

#
# the name of the backup file. file name format is backup.2000.01.12.at.22.59.48.tgz
#
WorkingDirectory="/usr/local/etc/freshports/"
BackupFile="freshports.backup.`date +%Y.%m.%d.at.%H.%M.%S`.tgz"
TempFreshportsFile="freshports.backup.txt"
TempFreshportsForumFile="freshports.phorum.backup.txt"

#
# dump the database.
# make the following replacements:
#
#     userid     - the user id to use when connecting to the database
#     password   - the password for the above user
#     database   - the name of database to dump
#     /pathto/   - the path to the backup file
#
/usr/local/bin/mysqldump -uroot -c --add-drop-table freshports   > $WorkingDirectory$TempFreshportsFile
/usr/local/bin/mysqldump -uroot -c --add-drop-table fpfeedbackup > $WorkingDirectory$TempFreshportsForumFile
#
# compress it
#
tar cfz $BackupFile $WorkingDirectory$TempFreshportsFile $WorkingDirectory$TempFreshportsForumFile

#
# copy it offsite
#
#ftp -n -v ducky.int.nz.freebsd.org  <<EoF
#        user ftpbackup ftpbackup
#        bin
#        prompt
#        mput $BackupFile
#EoF

/usr/bin/scp $BackupFile dan@ns1.unixathome.org:$BackupFile

#
# remove the files we created
#
#rm $BackupFile $WorkingDirectory$TempFreshportsFile $WorkingDirectory$TempFreshportsForumFile
