#
# $Id: README.txt,v 1.3.2.1 2002-11-24 17:00:27 dan Exp $
#
#
# Copyright (c) 2001-2002 DVL Software
#
When installing the scripts, be sure to modify the "use lib" entry
in load_xml_into_db.pl to point to the directory in which 
load_xml_into_db.pl resides.

The following packages are needed to run these scripts:

http://search.cpan.org/search?dist=File-PathConvert
http://www.cpan.org/authors/id/R/RB/RBS/File-PathConvert-0.85.tar.gz

textproc/p5-XML-Node
http://search.cpan.org/search?dist=XML-Node
http://www.cpan.org/authors/id/C/CH/CHANG-LIU/XML-Node-0.10.tar.gz

textproc/p5-XML-Writer
http://search.cpan.org/search?dist=XML-Writer
http://www.cpan.org/authors/id/DMEGG/XML-Writer-0.4.tar.gz

mail/p5-Mail-Sender

adjust this line in load_xml_into_db.pl:
use lib '/home/lists/scripts';



And you also need to run dir-create.sh
