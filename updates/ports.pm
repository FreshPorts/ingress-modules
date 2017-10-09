#!/usr/local/bin/perl
#
# $Id: ports.pm,v 1.24 2001-11-13 14:52:58 dan Exp $
#

package	ports;
require	Exporter;

#use strict;

use File::PathConvert;

my $PORTSBASEDIR = "/usr/ports";
my $SCRIPTDIR    = "/home/freshports.org/scripts";

@ISA	= qw(Exporter);
@EXPORT	= qw(PortUpdate ExtractCategoryFromDirectory GetDescrAndHomePage ReadFile PackageExists RefreshPort SendWatchNotice FilesWhichPromptRefresh RefreshOnePort CreateDailySummary GetNeedsRefreshForNewPort GetPortCategory GetPortID CreateCategory SendWatchNoticePersonal);


# * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
# * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
# * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
# * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
#
# DO NOT MODIFY THE BELOW VALUES WITHOUT ALSO CHANGING THE SAME VALUES IN updates.pl

my $FILE_MAKEFILE	= "Makefile";
my $FILE_DESCRIPTION	= "pkg-descr";
my $FILE_COMMENT	= "pkg-comment";
my $FILE_MAKEFILECOMMON	= "Makefile.common";
my $FILE_MAKEFILEMAN	= "files/Makefile.man";

my %FilesWhichPromptRefresh = (
    $FILE_MAKEFILE       => 1,
    $FILE_DESCRIPTION    => 2,
    $FILE_COMMENT        => 4,
    $FILE_MAKEFILECOMMON => 8,
    $FILE_MAKEFILEMAN    => 16,
);

# DO NOT MODIFY THE ABOVE VALUES WITHOUT ALSO CHANGING THE SAME VALUES IN updates.pl

# * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
# * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
# * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
# * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *

#sub GetPortID($port, $categoryid, $dbh) {
sub GetPortID($;$;$) {
   my $port       = shift;
   my $categoryid = shift;
   my $dbh        = shift;     
   
   my $PortID = 0;      
   
   my $sql = "select id, needs_refresh, status from ports where name = '" . $port . "' and primary_category_id = $categoryid";
   print $sql, "\n";
   my $sth = $dbh->prepare($sql);

   $sth->execute ||
      die "Could not execute SQL statement ... maybe invalid?";

   my @row=$sth->fetchrow_array;

   if (@row) {
      print "something found\n";
      $PortID = $row[0];   
   } else {
      print "nothing found\n";
   }       

   print "port id = " . $PortID . "\n";

   return $PortID;
}

sub GetNeedsRefreshForNewPort($;$) {
#
# When a new port is imported, we need to get the
# makefile and determine whether or not this port
# uses a description or comments file.  If it does,
# then we adjust needs_refresh accordingly.
# Note that some ports use another ports description
# or comments file.  Therefore we may not have
# to fetch those files in order to complete
# the importing of a new port
#
# this function tells you what files are needed by first fetching the Makefile
# and using that to determine the other information.

   my $category      = shift;
   my $port          = shift;
   my $FILE          = $FILE_MAKEFILE;

   my $needs_refresh = 0;

   print "category = $category\n";
   print "port     = $port\n";

   #
   # fetch the makefile for this port
   #
   `sh $SCRIPTDIR/fetch-cvs-file.sh $category $port $FILE`;

   if (($? >> 8)) {
      #
      # This might be a nice place to retry a fetch, or send an email
      #
      print "that fetch failed.  What do to?\n";
      my $FetchWorked = 0;

      # and we're outta here
   } else {
      my $MakeDir = "$PORTSBASEDIR/$category/$port";
      print "now doing a chdir to $MakeDir\n";
      chdir "$MakeDir";

      #
      # create this directory to catch errors
      # such as the pre-everything having only one ':'
      #
      mkdir "pkg",0;

      my $makecommand = "make -V DESCR -V COMMENT -f $PORTSBASEDIR/$category/$port/$FILE_MAKEFILE";

      # remove previously created directory
      rmdir "pkg";

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

         my $entry = $FILE_DESCRIPTION;
         if ($DESCR eq "$PORTSBASEDIR/$category/$port/$entry") {
            print "this port has it's own $entry\n";
            my $index = $FilesWhichPromptRefresh{$entry};
            if ($index) {
               print "index = $index\n";
               $needs_refresh |= $index;
            }
         } else {
            print "this port uses $DESCR\n";
         }

         $entry = $FILE_COMMENT;

         $COMMENT = File::PathConvert::realpath($COMMENT);
         if ($COMMENT eq "$PORTSBASEDIR/$category/$port/$entry") {
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
      } else {
         print "error executing make command: " . $?;
      }
   }

  return $needs_refresh;
}


sub SendWatchNotice($) {

  my $Bcc = shift;

   open(SENDMAIL, "|/usr/sbin/sendmail -oi -t")
                    or die "Can't fork for sendmail: $!\n";

print SENDMAIL <<"EOF";
From: FreshPorts watch daemon <freshports-watch\@freshports.org>
To: freshports-watch\@freshports.org
Bcc: $Bcc
Subject: FreshPorts watch list notification

This message was generated by the FreshPorts Watch Daemon.  Something 
on your watch list has changed.  Please refer to 
https://freshports.org/watch.php for details.

Cheers and thanks for your support.

--

You are receiving this message as part of the service you joined at
https://freshports.org/ but if you no longer wish to receive such messages,
please go to https://freshports.org/customize.php and disable mailings.

If a problem occurs, please send details, including the email address in
question, to postmaster\@freshports.org.
EOF

   close(SENDMAIL)     or warn "sendmail didn't close nicely";

}

sub SendWatchNoticePersonal($;$;$) {

  my $To            = shift;
  my $FrequencyLong = shift;
  my $Body          = shift;

   open(SENDMAIL, "|/usr/sbin/sendmail -oi -t")
                    or die "Can't fork for sendmail: $!\n";

print SENDMAIL <<"EOF";
From: FreshPorts watch daemon <freshports-watch\@freshports.org>
To: $To
Subject: FreshPorts $FrequencyLong notification

This message was generated by the FreshPorts Watch Daemon and highlights
your selected ports which have changed since the last notification.  You
have chosen to receive these notices on a $FrequencyLong basis.

$Body

Please refer to https://freshports.org/watch.php for details.

Cheers and thanks for your support.

--

You are receiving this message as part of the service you joined at
https://freshports.org/ but if you no longer wish to receive such messages,
please go to https://freshports.org/customize.php and disable mailings.

If a problem occurs, please send details, including the email address in
question, to postmaster\@freshports.org.
EOF

   close(SENDMAIL)     or warn "sendmail didn't close nicely";

}

# =================================    
sub ExtractCategoryFromDirectory($) {

   my $dir = shift;

print "directory = $dir\n";

   # split the dir into separate elements
   my @fields = split(/\//, $dir);

   #grab the last one.
   my $category = $fields[$#fields];

print "category = $category\n";

   # who's your daddy?
   return $category
}
   

# =================================
sub PackageExists($) {

   my $package = shift;
   my $exists  = "N";

   open F,"/usr/local/etc/freshports/packages.exists";

LINE:
   while(<F>){
#      if(/$package/) {
       if(index($_, $package) != -1 ) {
         $exists = "Y";
         last LINE;
      }
   }
   close F;
                                                                
   return $exists;                                              
}  



# =================================
sub ReadFile($) {

   my $file = shift;
   my $content;

   open F,$file;

   $content = "";
   while(<F>){
      $content .= $_;
   }

   close F;

   return $content;
}


# =================================
sub GetDescrAndHomePage($) {

   my $file = shift;
   my $url;
   my $DESCR;

   open F,$file;

   $DESCR = "";
   while(<F>){
      $DESCR .= $_;
      if(/WWW:(.*)/) {

#print "found a home page of $url\n";

         $url = $1;
         $url =~  s/^\s+//g;
      }
   }

   close F;                              
                                                                
   my @result = ($DESCR, $url);                                    
                                                                
   return @result;                                              
}


# =================================
sub GetCategoryFromCategories($) {
   my $categories = shift;
   my $category;

   ($category) = split(/ /s, $categories);

   return $category;
}


# =================================

sub CreateCategory($;$;$;$;$) {
   my $system      = shift;
   my $category    = shift;
   my $description = shift;
   my $is_primary  = shift;
   my $dbh         = shift;

   # create a new entry in the category table
   # we only create primary categories here.

# enhancement:
# note that ports/<category>/pkg/COMMENT contains the category description.
# one day, we might want to start using that.
#
# Dan Langille 2001.03.26
#
   my $sql = "insert into categories (system, name, description, is_primary) values \
             ('$system', '$category', '$description', '$is_primary')";

   print "\n",$sql, "\n";

   my $sth = $dbh->prepare($sql);
                       
   $sth->execute ||
        die "Could not execute insert categories SQL statement ... maybe invalid?";
                  
   my $CategoryID = $sth->{'mysql_insertid'};
                   
   return $CategoryID;
}

# =================================
#sub GetPortCategory($category, $dbh) {
sub GetPortCategory($;$) {
   my $category = shift;
   my $dbh      = shift;

   my $sql = "select id from categories where name = '" . $category . "'";

   print "\n",$sql, "\n";

   my $sth = $dbh->prepare($sql);

   $sth->execute ||
        die "Could not execute SQL statement ... maybe invalid?";


   my @row=$sth->fetchrow_array;

   print "\nGetPortCategory = $sql which gives ", $row[0], "\n";

   return $row[0];
}

sub PortUpdate($;$;$;$;$;$;$;$;$;$;$;$;$;$;$;$;$;$;$) {
   my $name             = shift;
   my $portname         = shift;
   my $category         = shift;
   my $descrfile        = shift;
   my $categories       = shift;
   my $portversion      = shift;
   my $commentfile      = shift;
   my $maintainer       = shift;
   my $extractsuffix    = shift;
   my $mastersites      = shift;
   my $builddepends     = shift;
   my $rundepends       = shift;
   my $shortdescription = shift;
   my $longdescription  = shift;
   my $homepage         = shift;
   my $packageexists    = shift;
   my $forbidden	= shift;
   my $broken		= shift;
   my $dbh              = shift;

   my $result = 0;

   # do some tidy up to add slashes

   #  these bits might have \'s.
   $longdescription  =~ s/\\/\\\\/g;
   $shortdescription =~ s/\\/\\\\/g;
   $forbidden        =~ s/\\/\\\\/g;
   $broken           =~ s/\\/\\\\/g;

   #  these bits might have quotes.
   $longdescription  =~ s/\'/\\'/g;
   $shortdescription =~ s/\'/\\'/g;
   $forbidden        =~ s/\'/\\'/g;
   $broken           =~ s/\'/\\'/g;

   if ($name ne $portname) {
      print "*************** port ('$name') differs from portname('$portname')\n";
   }

   print " 0 $name\n";
   print " 1 $portname\n";
   print " a $category\n";
   print " 2 $descrfile\n";
   print " 3 $categories\n";
   print " 4 $portversion\n";
   print " 5 $commentfile\n";
   print " 6 $maintainer\n";
   print " 7 $extractsuffix\n";
   print " 8 $mastersites\n";
   print " 9 $builddepends\n";
   print "10 $rundepends\n";
   print "11 $shortdescription\n";
   print "12 $longdescription\n";
   print "13 ";
   if (defined($homepage)) {
      print "$homepage";                 # this may be an unitialized value
   }
   print "\n";
   print "14 $packageexists\n";

   # this asks for user input
   #<STDIN>;

   #return;

   my $categoryid = GetPortCategory($category, $dbh);
   if (!$categoryid) {
      print "ERROR *** could not find category for $category\n";
      return -2;
   }

   # update the port, creating it if necessary

   my $sql = "select id from ports where name = '$name' and primary_category_id = $categoryid";
   print "sql = ", $sql, "\n";
   my $sth = $dbh->prepare($sql);

   $sth->execute ||
      die "Could not execute SQL statement ... maybe invalid?";

   my @row=$sth->fetchrow_array;

   if (@row) {
      print "something found\n";
   } else {
      print "nothing found\n";
   }

   # Get the short description (and escape them)
   # Get the long description (and escape them)
   # get homepage
   # get package exists

   print "port ID found = ", $row[0], "\n";
   if (!@row) {
      # no such port.  create it.
      $sql = "insert into ports (name,                                                                    \
              primary_category_id, system, version, date_created,                                         \
              short_description, long_description, maintainer, categories,                                \
              date_last_refreshed, needs_refresh, homepage, master_sites, extract_suffix, package_exists, \
              status, depends_run, depends_build, forbidden, broken) values (";

      $sql .= "'$name', $categoryid ,                                                     \
              'FreeBSD', '$portversion', current_timestamp, '$shortdescription',          \ 
              '$longdescription', '$maintainer', '$categories', current_timestamp, 'N', ";

      if (defined($homepage)) {
         $sql .= "'$homepage', ";
      } else {
         $sql .= "NULL, ";
      }

      $sql .= "'$mastersites', '$extractsuffix', '$packageexists', 'A',       \
               '$rundepends', '$builddepends', '$forbidden', '$broken')";

      print "$sql\n";

      $sth = $dbh->prepare($sql) || 
         die "Could not insert statement ... maybe invalid? " . mysql_error() ;

      $sth->execute ||
         die "Could not insert statement ... maybe invalid? " . mysql_error();
   } else {
      # update the time on the port
      $sql = "update ports set \ 
              version = '$portversion', short_description = \
              '$shortdescription', long_description = '$longdescription', maintainer = \
              '$maintainer', categories = '$categories', date_last_refreshed = \
              current_timestamp, ";

      if (defined($homepage)) {
         $sql .= "homepage = '$homepage',";
      } else {
         $sql .= "homepage = NULL,";
      }

#
# This may be a source of possible problems.  We may have to start locking the table before doing this.
# otherwise one update may clear the needs_refresh flags set by another update.
# Not a really serious problem, but a definite annoyance.
#
      $sql .= " master_sites = '$mastersites', \
                extract_suffix = '$extractsuffix', package_exists = '$packageexists', \
                needs_refresh = 0, depends_run = '$rundepends', depends_build = '$builddepends', \
                forbidden = '$forbidden', broken = '$broken' \
                where id = $row[0]";

      print "$sql\n";

      $sth = $dbh->prepare($sql) || die "Could not prepare ... maybe invalid?" . mysql_error();

      $sth->execute ||
         die "Could not execute update statement ... maybe invalid?";
   }

   return $result;
}


sub RefreshPortNoChecking($;$;$;$;$) {

   my $DirectoryOfMakeFile = shift;
   my $Category            = shift;
   my $Port                = shift;
   my $NameOfMakefile      = shift;
   my $dbh                 = shift;


   # a return of zero indicates success.
   my $result = 0;

   #
   # if we don't change the working dir, stuff like descrpath will not
   # contain /usr/ports/...etc.  It will look more like this:
   #     /usr/home/dan/walkports/
   # That's because DESCR is defined as .{CURDIR}/etc more or less
   #


   #
   # create this directory to catch errors
   # such as the pre-everything having only one ':'
   #
   mkdir "pkg",0;

   my $makecommand = "make -V PORTNAME -V PKGNAME -V DESCR -V CATEGORIES -V PORTVERSION " .
         "-V COMMENT -V MAINTAINER -V EXTRACT_SUFX -V MASTER_SITES " .
         "-V BUILD_DEPENDS -V RUN_DEPENDS -V FORBIDDEN -V BROKEN -f $DirectoryOfMakeFile/$NameOfMakefile";

   print "makecommand = $makecommand\n";
   chdir "$DirectoryOfMakeFile";

   (my $portname, my $packagename, my $descrpath, my $categories, my $portversion, my $commentfile,
    my $maintainer, my $extractsuffix, my $mastersites, my $builddepends,
    my $rundepends, my $forbidden, my $broken) = split(/\n/s, `$makecommand`);

   # remove previously created directory
   rmdir "pkg";

   #
   # we need to check this return value.  if it fails, we need to know
   #

   if ($? == 0) {

   print " 0 $Port\n";
   print " 1 $portname\n";
   print " a $Category\n";
   print " 2 $packagename\n";
   print " 3 $descrpath\n";
   print " 4 $categories\n";
   print " 5 $portversion\n";
   print " 6 $commentfile\n";
   print " 7 $maintainer\n";
   print " 8 $extractsuffix\n";
   print " 9 $mastersites\n";
   print "10 $builddepends\n";
   print "11 $rundepends\n";

   (my $longdescription, my $homepage) = GetDescrAndHomePage($descrpath);
   my $shortdescription = ReadFile($commentfile);

   my $packageexists = PackageExists($packagename . ".tgz");

   # because we are adding in \ before the quotes,
   # we need to quote the \'s first.

   #  these bits might have \'s.
#   $longdescription  =~ s/\\/\\\\/g;
#   $shortdescription =~ s/\\/\\\\/g;

#   #  these bits might have quotes.
#   $longdescription  =~ s/\'/\\'/g;
#   $shortdescription =~ s/\'/\\'/g;

   print "12 $shortdescription\n";
   print "13 $longdescription\n";
   print "14 ";
   if (defined($homepage)) {
      print "$homepage";
   }
   print "\n";
   print "15 $packageexists\n";
   print "16 $forbidden\n";
   print "17 $broken\n";

   print "\n ---------------------------------------- \n";

   $result = PortUpdate ($Port, $portname, $Category, $descrpath, $categories, $portversion,
      $commentfile, $maintainer, $extractsuffix, $mastersites, $builddepends,
      $rundepends, $shortdescription, $longdescription, $homepage, $packageexists, $forbidden, $broken, $dbh);
   } else {
      $result = -1;
   }

   return $result;
}

sub RefreshPort($;$;$) {

   my $dirname = shift;
   my $port    = shift;
   my $dbh     = shift;

   #
   # a return of zero indicates success
   #
   my $result = 0;

   print "... now checking $dirname/$port .... ";
   if (-d "$dirname/$port") {
      #
      # at one time, $IGNOREDPORTS contained . and .. but that caused
      # problems with port names which contained a '.'
      # hence, this solution.  Also, pkg causes similar problems
      # as the port pkg_remove would match that
      # my $IGNOREDPORTS = "pkg|CVS|apache13-php-fp-modssl|Makefile";
      if ($port eq "." || $port eq ".." || $port eq "pkg" || $port eq "CVS" || $port eq $FILE_MAKEFILE) {
         print "port is in the IGNORE list... skipping\n";
      } else {
         if (!-e "$dirname/$port/$FILE_MAKEFILE") {
            print " ...$FILE_MAKEFILE does not exist (port must be in Attic)\n";
         } else {
            print "...now looking at $dirname/$port/$FILE_MAKEFILE\n";

            my $category = ExtractCategoryFromDirectory($dirname);

            $result = RefreshPortNoChecking("$dirname/$port", $category, $port, $FILE_MAKEFILE, $dbh);

         }  # else yes, the Makefile does exist.
      }
   } else {
      print "directory does not exist... skipping\n";
      $result = -1;
   }

   return $result;
}

sub RefreshOnePort($;$;$;$) {
   my $category      = shift;
   my $port          = shift;
   my $needs_refresh = shift;
   my $dbh           = shift;

   # a return of zero indicates success.
   my $result        = 0;

   my $dirname = "$PORTSBASEDIR/$category";

   print " now in RefreshOnePort.  press enter to continue";
# <STDIN>;

   print " which becomes $dirname : $port\n";

   # now find out what needs to be refreshed....

   print "needs_refresh = $needs_refresh\n";

   my $FetchWorked = 1;

# 2000.06.09 - Dan Langille
#
# Here is the question I asked in #perl.  Can you tell nobody else
# was active?
#
# I'm having trouble with a hash.  the definition is hardcoded as a
# constant at the top of the file.  I use the has in a function
# which called repeatedly.  In the function I do this: while ((my
# $key, my $value) = each %FilesWhichPromptRefresh) {...etc  but:
# 
# if I exit the while using "last", the next time I call the
# function, it never enters the while.  I suspect the hash is either
# being cleared out or needs to be "reset".  sound familiar?
# 
# looking at the documentation for values, it mentions that function
# "resets HASH's iterator".  sounds like something I need.
# OK.  doing this before the while fixes the problem: keys
# %FilesWhichPromptRefresh;  <== but there must be a better. way.
#
   keys %FilesWhichPromptRefresh;

   while ((my $key, my $value) = each %FilesWhichPromptRefresh) {
      if ($needs_refresh & $value) {
         print "now fetching $key\n";
         #
         # should this be path hardcoded?
         # if it isn't, the chdir which occurs in RefreshPort below
         # makes this call fail (because it can't find the script).
         #
         
         `sh $SCRIPTDIR/fetch-cvs-file.sh $category $port $key`;

         if (($? >> 8)) {
            #
            # This might be a good place to refetch, loop. or send an email.
            #
            print "that fetch failed.  What do to?\n";
            $FetchWorked = 0;

            # and we're outta here
            last;
         }
      }
   }

#   print "press enter to continue "; <STDIN>;

   if ($FetchWorked) {
      print "refreshing port...\n";
      $result = RefreshPort($dirname, $port, $dbh);
   } else {
      print "can't do anything about that port...\n";
      $result = 1;
   }

   return $result;
}


sub CreateDailySummary($;$) {

   my $PathToUse       = "/usr/local/etc/freshports/archives";  # must NOT include a trailing /
   my @myrow;
   my $CommitDateStart = shift;
   my $dbh             = shift;

   my $sql = "select ports.id, ports.name, ports.version " .
             "from ports, change_log_port, change_log ".
             "where ports.id                      = change_log_port.port_id ".
             "  and change_log_port.change_log_id = change_log.id ".
             "  and change_log.commit_date between '$CommitDateStart' and Date_Add('$CommitDateStart', INTERVAL 1 DAY) " .
             "order by change_log.commit_date desc";

   my $sth = $dbh->prepare($sql);

   $sth->execute ||
        die "Could not execute SQL statement\n--$sql--\n... maybe invalid?";


   print "$sql\n";

#   if ($sth->num_rows) {
#      print "$sth->num_rows rows in that result\n";
#   }

#   print "press enter to continue"; <STDIN>;

   umask(02);
   # create the output file name gradually, ensuring the directories exist

   my $OutputFile = $PathToUse . "/" . substr($CommitDateStart, 0, 4);

   if (-d $OutputFile) {
      print "'$OutputFile' exists\n";
   } else {
      print "'$OutputFile' does not exist\n";
      print "   trying to mkdir '$OutputFile'\n";
      if (mkdir $OutputFile, 0775) {
      } else {
         print "Could not create directory $OutputFile\n";
         return 1;
      }
   }

   $OutputFile .= "/" . substr($CommitDateStart, 5, 2);
   if (-d $OutputFile) {
      print "'$OutputFile' exists\n";
   } else {
      print "   trying to mkdir '$OutputFile'\n";
      if (mkdir $OutputFile, 0775) {
      } else {
         print "Could not create directory $OutputFile\n";
         return 2;
      }
   }

   $OutputFile .= "/" .  substr($CommitDateStart, 8, 2) . ".inc";
   print "   trying to open '$OutputFile'\n";
   open FILE, ">$OutputFile"  || die "Could not open $OutputFile";
   
   if (*FILE) {
      print "that file was opened.  now writing output\n";
      my $count =0;
      while (@myrow = $sth->fetchrow_array) {
         print FILE '<a href="port-description.php?port=';
         print FILE $myrow[0] . '"><font size="-1">' . $myrow[1] . " ";
         print FILE $myrow[2] . "</font></a><br>\n";     
         $count++;
      }
             
      print "i wrote out $count records\n";

      close FILE;
   } else {
      print "could not open $OutputFile\n";
      return 3;
   }
   
   return 0;
}
