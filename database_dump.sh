#!/bin/sh
#
# $Id: database_dump.sh,v 1.8.2.2 2003-05-31 13:34:24 dan Exp $
#
# Copyright (c) 1999-2003 DVL Software
#
# postgresql database backup
#

#
# the name of the backup file. file name format is
# freshports.backup.2000.01.12.at.22.59.48.tgz
#
WorkingDirectory=${HOME}
BackupFile="nezlok.freshports.backup.`date +%Y.%m.%d.at.%H.%M.%S`.tgz"
TempFreshportsFile="freshports.backup.txt"
TempFreshPortsPhorum=freshports.phorum.backup.txt
TempPhpAds=freshports.phpads.backup.txt

#
# dump the database.
# make the following replacements:
#
#     userid     - the user id to use when connecting to the database
#     password   - the password for the above user
#     database   - the name of database to dump
#     /pathto/   - the path to the backup file
#
echo "/usr/local/bin/pg_dump freshports > $WorkingDirectory/$TempFreshportsFile"
/usr/local/bin/pg_dump freshports > $WorkingDirectory/$TempFreshportsFile

/usr/local/bin/pg_dump fpphorum   > $WorkingDirectory/$TempFreshPortsPhorum
echo "/usr/local/bin/pg_dump fpphorum   > $WorkingDirectory/$TempFreshPortsPhorum"

/usr/local/bin/pg_dump phpads     > $WorkingDirectory/$TempPhpAds
echo "/usr/local/bin/pg_dump phpads     > $WorkingDirectory/$TempPhpAds"

#
# compress it
#
echo tar cvfz $BackupFile $WorkingDirectory/$TempFreshportsFile $WorkingDirectory/$TempFreshPortsPhorum $WorkingDirectory/$TempPhpAds
tar cvfz $BackupFile $WorkingDirectory/$TempFreshportsFile $WorkingDirectory/$TempFreshPortsPhorum $WorkingDirectory/$TempPhpAds

#
# copy it offsite
#

echo /usr/bin/scp -P 2222 $BackupFile ftpbackup@bast.unixathome.org:
/usr/bin/scp -P 2222 $BackupFile ftpbackup@bast.unixathome.org:

#
# remove the files we created
#
echo $BackupFile $WorkingDirectory/$TempFreshportsFile $WorkingDirectory/$TempFreshPortsPhorum $WorkingDirectory/$TempPhpAds
rm $BackupFile $WorkingDirectory/$TempFreshportsFile $WorkingDirectory/$TempFreshPortsPhorum $WorkingDirectory/$TempPhpAds
