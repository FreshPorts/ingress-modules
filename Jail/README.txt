FreshPorts now uses a chroot strategy for extracting information from the ports tree.

To create the chroot structure, which I often refer to as a jail, issue the
following command:

 ./create-jail-directories.sh ~/tmp/JAIL /home/dan/PORTS-SVN

The directory structure will be created at ~/tmp/JAIL
The system expects an up-to-date copy of the ports tree at /home/dan/PORTS-SVN
The scripts required for the jail will be copied to the base directory of
the jail.  These scripts are located in the scripts subdirectory relative to
the file you are reading now.

This script will output a number of mount points which need to be added to
/etc/fstab.  After doing that, issue a 'mount -a' command and your jail
structure is complete and ready to do.
