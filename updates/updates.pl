#!/usr/bin/perl

#
# Port Updater for FreshPorts
# takes output of LogMunger and updates the database
# written by Dan Langille
# copyright 2000 DVL Software
#

use DBI;

#
# These are the files which require a port be refreshed from the raw Makefile
#
$FilesWhichPromptRefresh = "Makefile|pkg/DESCR|pkg/COMMENT";

#sub GetPortCategory($category, $dbh) {
sub GetPortCategory($;$) {
   my $category = shift;
   my $dbh = shift;

   my $sql = "select id from categories where name = '" . $category . "'";

   my $sth = $dbh->prepare($sql);

   $sth->execute ||
        die "Could not execute SQL statement ... maybe invalid?";


   @row=$sth->fetchrow_array;

   print "\nGetPortCategory = $sql which gives ", @row[0], "\n";


   return @row[0];
}

#ChangeLogInsert($committer, $timestamp, $description, $dbh);
sub ChangeLogInsert($;$;$;$) {
   my $committer   = shift;
   my $timestamp   = shift;
   my $description = shift;
   my $dbh         = shift;

   my $sql = "INSERT INTO change_log (commit_date, committer, update_description) \
           values ('$timestamp', '$committer', '$description')";

   my $sth = $dbh->prepare($sql);

   $sth->execute ||
        die "Could not execute change_log SQL statement $sql ... maybe invalid?";

   my $ChangeLogID = $sth->{'mysql_insertid'};

   return $ChangeLogID;
}

#ChangeLogDetailInsert($ChangeLogID, $PortID, $action, $details, $dbh);
sub ChangeLogDetailInsert($;$;$;$;$) {
   my $ChangeLogID = shift;
   my $PortID      = shift;
   my $action      = shift;
   my $details     = shift;
   my $dbh         = shift;

   my $change_type = '?';

   print "in ChangeLogDetailInsert change log ID is $ChangeLogID\n";

   if ($action eq "modify") {
      $change_type = 'M';
   } else {
      if ($action eq "remove") {
         $change_type = 'R';
      } else {
         if ($action eq "import") {
            $change_type = 'I';
         } else {
            if ($action eq "add") {
               $change_type = 'A';
           }
         }
      }
   }

   my $sql = "INSERT INTO change_log_details (change_log_id, port_id, change_type, details) \
                values ($ChangeLogID, $PortID, '$change_type', '$details')";

   print "ChangeLogDetailInsert sql is $sql\n";

   my $sth = $dbh->prepare($sql);

   $sth->execute ||
        die "Could not execute change_log_detail SQL statement $sql ... maybe invalid?";

   my $ChangeLogDetailID = $sth->{'mysql_insertid'};

   return $ChangeLogDetailID;
}

#PortUpdate ($ChangeLogID, $committer, $timestamp, $action, $description, $category, $port, $entry, $dbh) {
sub PortUpdate($;$;$;$;$;$;$;$;$) {
   my $ChangeLogID = shift;
   my $committer   = shift;
   my $timestamp   = shift;
   my $action      = shift;
   my $description = shift;
   my $category    = shift;
   my $port        = shift;
   my $entry       = shift;
   my $dbh         = shift;

   my $sql = "";

   print "change log ID is $ChangeLogID\n";

   $categoryid = GetPortCategory($category, $dbh);
   if ($category = '') {
      # email the main man
      open  MAIL, "|mail -s 'freshports error' $NotifyByMail";
      print MAIL "A category ('$category') was not found\n";
      print MAIL "$committer\n$timestamp\n$action\n$description\n$category\n$port\n$entry\n";
      close MAIL;
   } else {

      # update the port, creating it if necessary

      $sql = "select id, needs_refresh, status from ports where name = '" . $port . "' and primary_category_id = $categoryid";
      print $sql, "\n";
      $sth = $dbh->prepare($sql);
   
      $sth->execute ||
         die "Could not execute SQL statement ... maybe invalid?";

      @row=$sth->fetchrow_array;

      if (@row) {
         print "something found\n";
      } else {
         print "nothing found\n";
      }

      print "port id = " . @row[0] . "\n";

      if (!@row) {
         # no such port.  create it.
         $sql = "insert into ports (name, last_update, primary_category_id, " .
                "last_update_description, committer, date_created, needs_refresh, " .
                "status, package_exists, short_description) values (";
         # we assume above that the package does not exist until we are told otherwise.

         # we don't get a version when inserting, so we must fake it by supplying a name.
         # and the date created is this timestamp.  we used to use current_time,
         # but that defaults to local time, which is not necessarily the same time zone
         # which can give things like created > last_update.
         $sql .= "'$port', '$timestamp', $categoryid, '$description', " . 
                 "'$committer', '$timestamp', 'Y', 'A', 'N', '-- waiting for description --')";

         print "$sql\n";

         $sth = $dbh->prepare($sql);

         $sth->execute ||
            die "Could not execute SQL statement ... maybe invalid?";

         my $PortID = $sth->{'mysql_insertid'};

         print "newly created port has ID = $PortID\n";

         $sql = "insert into newports (name, primary_category_id) values ('$port', $categoryid)";

         $sth = $dbh->prepare($sql);

         $sth->execute ||
            die "Could not execute SQL port insert statement ... $sql maybe invalid?";

         my $last_change_log_detail_id = ChangeLogDetailInsert($ChangeLogID, $PortID, $action, $entry, $dbh);

         $sql = "update ports set last_change_log_detail_id = $last_change_log_detail_id where id = $PortID";

         $sth = $dbh->prepare($sql);

         $sth->execute ||
            die "Could not execute port update SQL statement ... $sql maybe invalid?";

      } else {
         my $PortID			= @row[0];
         my $NeedsRefreshOriginal	= @row[1];
         my $StatusOriginal		= @row[2];
         my $last_change_log_detail_id = ChangeLogDetailInsert($ChangeLogID, $PortID, $action, $entry, $dbh);

         # update the time on the port
         $sql = "update ports set last_update = '$timestamp', committer = '$committer', " .
                "last_update_description = '$description', last_change_log_detail_id = $last_change_log_detail_id ";



         if ($action eq "remove") {
            # make sure we aren't deleting this port!
            if ($entry eq "Makefile") {
               $sql .= ", status = 'D'";
               # if we are deleting a port, we don't need to refresh it.
               # we do this in case the port is already waiting for a refresh
               # when it is deleted.
               $sql .= ", needs_refresh = 'N'";
            }
         } else {

            #
            # depending on what has changed, we need to take action accordingly
            # if we are removing a file, we definitely don't need to refresh.
            # that's because any file which prompts a refresh, and is removed
            # pretty much means the port is being deleted.
            #

            if (index($FilesWhichPromptRefresh, $entry) != -1) {
               #
               # if the port has not been deleted
               #
               if ($StatusOriginal ne "D") {
                  $sql .= ", needs_refresh = 'Y'";
               }
            }
         }

         $sql .= " where id = $PortID";

         print "$sql\n";

         $sth = $dbh->prepare($sql);

         $sth->execute ||
            die "Could not execute SQL statement ... maybe invalid?";
      }
   } # else category is not blank
}

my $ChangeLogID;

$dbh = DBI->connect('dbi:mysql:freshports','updater','xyzzy');

$inputfile = 'data.txt';
$inputfile = 'sample.txt';
#$inputfile = 'abacus.txt';
$inputfile =  '/www/freshports.org/work/msgs-awk/20000421-13:30:45-NZST.39927.munged';
$ignoredirs = "Attic|distfiles|Mk|Tools|Templates";

#open (STDIN, $inputfile) || die "error opening";
@file=<STDIN>;
close(STDIN);
chomp(@file);

for($i=0; $i<=$#file; $i++) {
   $id = $i + 1;

   $line = $file[$i];

   ($committer, $timestamp, $action, $filename, $description, $extra)=split/\|/,$line;

#  these bits might have quotes.
   $committer   =~ s/\'/\\'/g;
   $description =~ s/\'/\\'/g;

   print "committer=", $committer, "\ntimestamp=", $timestamp, "\naction='",  $action, "'\nfilename=", $filename, "\ndescription=", $description, "\n";

   # split the file name into three parts.
   # $entry might have something like pkg/DESCR
   ($category, $port, $entry) = split/\//,$filename, 3;

  print "category=$category\nport=$port\nentry=$entry\n";
#  exit;

   #
   # this is where we can pick up on special things
   #

   if ($category eq "." and $port eq "INDEX") {
      #
      # ahh, the index has changed, do we want to know?
      #
      print "ahh, the index has changed, do we want to know?";
   } else {
      if ($entry || (!$entry && $action eq 'import')) {

         # we ignore certain categories and always ignore /usr/ports/<category>/Makefile.
         if (($category !~ /$ignoredirs/) && ($port ne 'Makefile')) {
            #print '  ***';
            # we have a file in this port which is actually being updated.  Let's update the port.
            if (!defined($ChangeLogID)) {
               # insert main details into the change_log table.
               $ChangeLogID = ChangeLogInsert($committer, $timestamp, $description, $dbh);
               print "change log ID is $ChangeLogID\n";
            }
            print "change log ID is still $ChangeLogID\n";
            PortUpdate ($ChangeLogID, $committer, $timestamp, $action, $description, $category, $port, $entry, $dbh)
         } else {
            print "ignoring $category/$port\n";
         }
      } else {
        print 'not processing this update as it does not meet the criteria';
      }
   }
 
  print "\n\n ===================================\n\n";

#exit;
}

`touch /usr/local/etc/freshports/msgs/lastupdate`;
