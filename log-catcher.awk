#
#  FreshPorts log catcher. This catches the raw data from
#  cvs-all messages.  It is designed to work from the data
#  supplied in the cvs-all mailing list.
#
#  written by icmpecho.
#
#  copyright 2000 DVL Software Limited
#  all rights reserved.
#


BEGIN {
 OUTDIR="/usr/local/etc/freshports.test/msgs/" ;
 MUNGER="/usr/bin/awk -f /usr/local/etc/freshports.test/log-munger.awk";

 UPDATER = "/usr/bin/perl /usr/local/etc/freshports.test/updates/updates.pl";

 getline pid<"/dev/pid"

 file=OUTDIR strftime("%Y%m%d.%H.%M.%S.%Z.")  pid ".txt";
 filenext = file ".munged";

 inheader=1;wasport=0;

 print "output directory = " OUTDIR;
 print "munger           = " MUNGER;
 print "updater          = " UPDATER;
 print "catch file       = " file;
 print "munged file      = " filenext;
 }

{
if(inheader==0) {
 if($1=="To" && $2=="Unsubscribe:" && $NF=="majordomo@FreeBSD.org") exit;
 print $0>file;
 next;
 }
if($1=="In-Reply-To:") exit;
if($1=="Subject:" && ($2!="cvs" || $3!="commit:" || substr($4,1,6)!="ports/")) exit;
if(NF==0) {
 inheader=0;getline;
 if(NF!=4 || length($4)!=3 || length($2)!=10 || length($3)!=8) exit;
 print $0>file;wasport=1;
 }

}

END {
if(wasport) {

 /* invoke the munger now */
 cmd=MUNGER " < " file " > " filenext;
 /* cmd2=MUNGER " <" file "|" UPDATER; */
 system(cmd);

 print "cmd = " cmd;

 /* now invoke the updater */
 cmd2 = "/bin/cat " filenext " | " UPDATER " 2>&1 | cat - > " filenext ".out";
 system(cmd2);

 print "cmd2 = " cmd2;;
/* print cmd2; */
}
}

