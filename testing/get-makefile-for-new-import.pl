#!/usr/bin/perl -w

#
# When a new port is imported, we need to get the 
# makefile and determine whether or not this port
# uses a pkg/DESCR and pkg/COMMENTS.  If it does,
# then we adjust needs_refresh accordingly.
# Note that some ports use another ports pkg/DESCR
# and pkg/COMMENTS file.  Therefore we may not have
# to fetch those files in order to complete
# the importing of a new port
#
# Dan Langille 2000.06.26
# Copyright 2000 - DVL Software Limited
# All rights reserved.
#


use strict;
use ports;
use File::PathConvert;

use DBI;

my $BASEDIR = "/usr/ports";

my %FilesWhichPromptRefresh = (
   "Makefile"    => "1",
   "pkg/DESCR"   => "2",
   "pkg/COMMENT" => "4",
);

my $result = 0;

sub GetMakefileForNewPort($;$) {
   my $category      = shift;
   my $port          = shift;
   my $FILE          = 'Makefile';

   print "category = $category\n";
   print "port     = $port\n";

   #
   # fetch the makefile for this port
   #
   `sh /home/dan/walkports/fetch-cvs-file.sh $category $port $FILE`;

   if (($? >> 8)) {
      print "that fetch failed.  What do to?\n";
      my $FetchWorked = 0;

      # and we're outta here
   } else {
      my $needs_refresh = 0;

      my $MakeDir = "$BASEDIR/$category/$port";
      print "now doing a chdir to $MakeDir\n";
      chdir "$MakeDir";

      my $makecommand = "make -V DESCR -V COMMENT -f $BASEDIR/$category/$port/Makefile";

      print "makecommand = $makecommand\n";
      (my $DESCR, my $COMMENT) = split(/\n/s, `$makecommand`);

      #
      # we need to check this return value.  if it fails, we need to know
      #

      if ($? == 0) {
         print "raw       data DESCR   = $DESCR\n";
         print "raw       data COMMENT = $COMMENT\n";

         #
         # some ports (e.g. korean/netscape47-communicator) use
         # ../ in their path names.  We must remove that in order
         # to find out if have to retrieve a file in our path
         #

         $DESCR   = File::PathConvert::realpath($DESCR);
         $COMMENT = File::PathConvert::realpath($COMMENT);

         print "converted data DESCR   = $DESCR\n";
         print "converted data COMMENT = $COMMENT\n";

         my $entry = 'pkg/DESCR';
         if ($DESCR eq "$BASEDIR/$category/$port/$entry") {
            print "this port has it's own $entry\n";
            my $index = $FilesWhichPromptRefresh{$entry};
            if ($index) {
               print "index = $index\n";
               $needs_refresh |= $index;
            }
         } else {
            print "this port uses $DESCR\n";
         }

         $entry = 'pkg/COMMENT';

         $COMMENT = File::PathConvert::realpath($COMMENT);
         if ($COMMENT eq "$BASEDIR/$category/$port/$entry") {
            print "this port has it's own $entry\n";
            my $index = $FilesWhichPromptRefresh{$entry};
            if ($index) {
               print "index = $index\n";
               $needs_refresh |= $index;
            }
         } else {
            print "this port uses $COMMENT\n";
         }

         print "after all that, needs_refresh = $needs_refresh\n";
      }
   }

  return $needs_refresh;
}

if (($#ARGV+1) == 2) {
   print "there are 2 arguments\n";
   my $category      = $ARGV[0];
   my $port          = $ARGV[1];
   my $FILE          = 'Makefile';

   GetMakefileForNewPort($category, $port);

} else {
   print "usage get-makefile-for-new-import.pl CATEGORY PORT\n";
}
