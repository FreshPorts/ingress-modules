#!/usr/bin/perl

#
# Port Updater for FreshPorts
# takes output of LogMunger and updates the database
# written by Dan Langille
# copyright 2000 DVL Software
#

use DBI;
use strict;
use lib '/usr/local/etc/freshports.test/updates';
use portschange;

my $Debug = 0;


# * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
# * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
# * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
# * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
#
# DO NOT MODIFY THE BELOW VALUES WITHOUT ALSO CHANGING THE SAME VALUES IN fetch-refresh-ports

my %FilesWhichPromptRefresh = (
   "Makefile"    => "1",
   "pkg/DESCR"   => "2",
   "pkg/COMMENT" => "4",
);

# DO NOT MODIFY THE ABOVE VALUES WITHOUT ALSO CHANGING THE SAME VALUES IN fetch-refresh-ports

# * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
# * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
# * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
# * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *

#sub GetPortCategory($category, $dbh) {
sub GetPortCategory($;$) {
   my $category = shift;
   my $dbh = shift;

   my $sql = "select id from categories where name = '" . $category . "'";

   my $sth = $dbh->prepare($sql);

   $sth->execute ||
        die "Could not execute SQL statement ... maybe invalid?";


   my @row=$sth->fetchrow_array;

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

#ChangePortInsert($ChangeLogID, $PortID, $dbh);
sub ChangePortInsert($;$;$) {
   my $ChangeLogID = shift;
   my $PortID      = shift;
   my $dbh         = shift;

   my $sql = "INSERT INTO change_log_port (change_log_id, port_id) \
           values ($ChangeLogID, $PortID)";

   print "ChangePortInsert => $sql\n";

   my $sth = $dbh->prepare($sql);

   $sth->execute ||
        die "Could not execute change_port SQL statement $sql ... maybe invalid?";

   my $ChangePortID = $sth->{'mysql_insertid'};

   print "ChangePortID = '$ChangePortID'\n";

   return $ChangePortID;
}

#ChangeLogDetailInsert($ChangePortID, $PortID, $action, $details, $dbh);
sub ChangeLogDetailInsert($;$;$;$;$) {
   my $ChangePortID = shift;
   my $PortID       = shift;
   my $action       = shift;
   my $details      = shift;
   my $dbh          = shift;

   my $change_type = '?';

   print "in ChangeLogDetailInsert change port ID is $ChangePortID\n";

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

   my $sql = "INSERT INTO change_log_details (change_log_port_id, port_id, change_type, details) \
                values ($ChangePortID, $PortID, '$change_type', '$details')";

   print "ChangeLogDetailInsert sql is $sql\n";

   my $sth = $dbh->prepare($sql);

   $sth->execute ||
        die "Could not execute change_log_detail SQL statement $sql ... maybe invalid?";

   my $ChangeLogDetailID = $sth->{'mysql_insertid'};

   return $ChangeLogDetailID;
}

#PortCreate ($port, $categoryid, $timestamp, $commitdescription, $dbh) {
sub PortCreate($;$;$;$;$) {
   my $port              = shift;
   my $categoryid        = shift;
   my $timestamp         = shift;
   my $commitdescription = shift;
   my $dbh               = shift;

   # no such port.  create it.
   my $sql = "insert into ports (name, primary_category_id, " .
          "date_created, needs_refresh, " .
          "status, package_exists, short_description) values (";

   # we assume above that the package does not exist until we are told otherwise.

   # we don't get a version when inserting, so we must fake it by supplying a name.
   # and the date created is this timestamp.  we used to use current_time,
   # but that defaults to local time, which is not necessarily the same time zone
   # which can give things like created > last_update.
   $sql .= "'$port', $categoryid, " .
           "'$timestamp', 7, 'A', 'N', '$commitdescription')";

   print "$sql\n";

   my $sth = $dbh->prepare($sql);

   $sth->execute ||
      die "Could not execute PortCreate SQL statement ... maybe invalid?";

   my $PortID = $sth->{'mysql_insertid'};

   print "newly created port has ID = $PortID\n";

#   $sql = "insert into newports (name, primary_category_id) values ('$port', $categoryid)";
#
#   $sth = $dbh->prepare($sql);
#
#   $sth->execute ||
#      die "Could not execute SQL port insert statement ... $sql maybe invalid?";

   return $PortID;
}

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
      $PortID = @row[0];
   } else {
      print "nothing found\n";
   }

   print "port id = " . $PortID . "\n";

   return $PortID;
}

#MarkPortAsRefreshNeeded ($PortID, $ChangeLogID, $action, $entry, $dbh) {
sub MarkPortAsRefreshNeeded($;$;$;$;$) {
   my $PortID      = shift;
   my $ChangeLogID = shift;
   my $action      = shift;
   my $entry       = shift;
   my $dbh         = shift;

   my $sql = "";
   my $PortWasCreated = "N";

   print "change log ID is $ChangeLogID\n";

   $sql = "select needs_refresh, status from ports where id =  " . $PortID;
   print $sql, "\n";
   my $sth = $dbh->prepare($sql);     
           
   $sth->execute ||
      die "Could not execute SQL statement ... maybe invalid?";

   my @row=$sth->fetchrow_array;

   my $NeedsRefreshOriginal       = @row[0];
   my $StatusOriginal             = @row[1];

   # we used to do this with the last_change_log_detail_id, but now we use ChangeLogID.
   # update the time on the port
   $sql = "update ports set last_change_log_id = $ChangeLogID ";

   if ($action eq "remove") {
      # make sure we aren't deleting this port!
      if ($entry eq "Makefile") {
         $sql .= ", status = 'D'";
         # if we are deleting a port, we don't need to refresh it.
         # we do this in case the port is already waiting for a refresh
         # when it is deleted.
         $sql .= ", needs_refresh = 0";
      }
   } else {

      #
      # depending on what has changed, we need to take action accordingly
      # if we are removing a file, we definitely don't need to refresh.
      # that's because any file which prompts a refresh, and is removed
      # pretty much means the port is being deleted.
      #

      my $index = $FilesWhichPromptRefresh{$entry};
      if ($index) {
         #
         # if the port has not been deleted
         #
         if ($StatusOriginal ne "D") {
            $sql .= ", needs_refresh = needs_refresh | $index";
         }
      }
   }

   $sql .= " where id = $PortID";

   print "$sql\n";

   $sth = $dbh->prepare($sql);

   $sth->execute ||
      die "Could not execute SQL statement ... maybe invalid?";
}

my $ChangeLogID;

#
# The contents of this hash is: $Ports{$category . "/" . $port} = [$PortID, $ChangePortID];
#
my %Ports;
my $NotifyByMail = "root";
my $PortID;
my $ChangePortID;

my $dbh = DBI->connect('dbi:mysql:SETDATABSEHERE','updater','PASSWORD');
if (!$dbh) {
   # email the main man
   open  MAIL, "|mail -s 'freshports error' $NotifyByMail";
   print MAIL "The updater could not connect to the databse\n";
   close MAIL;

   exit;
}

my $ignoredirs = "Attic|distfiles|Mk|Tools|Templates";

my $committer;
my $timestamp;
my $action;
my $filename;
my $description;
my $extra;
my $category;       
my $port;       
my $entry;       
my $categoryid;


my @file=<STDIN>;
close(STDIN);
chomp(@file);

for(my $i=0; $i<=$#file; $i++) {
   my $line = $file[$i];

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
         if ((index($ignoredirs, $category) == -1) && ($port ne 'Makefile')) {
            #print '  ***';
            # we have a file in this port which is actually being updated.  Let's update the port.

            #
            # the first thing we do, if we haven't already done it, is insert an entry into
            # the change_log table.  We do this only once per commit.  Hence the !defined($ChangeLogID)
            #
            if (!defined($ChangeLogID)) {
               # insert main details into the change_log table.
               if (!$Debug) {
                  $ChangeLogID = ChangeLogInsert($committer, $timestamp, $description, $dbh);
               }
               print "change log ID is $ChangeLogID\n";
            }
            print "change log ID is still $ChangeLogID\n";

            if ($Ports{$category . "/" . $port}) {
               print "ahhh, I see we've processed this port already...\n";
               # we've processed something for this port before

               # so get the PortID and ChangePortID
               $PortID       = $Ports{$category . "/" . $port}[0];
               $ChangePortID = $Ports{$category . "/" . $port}[1];
            } else {
               print "this port ('$category/$port') was not found in the hash table\n";
               $categoryid = GetPortCategory($category, $dbh);
               if ($categoryid == '') {
                  # email the main man
                  open  MAIL, "|mail -s 'freshports error' $NotifyByMail";
                  print MAIL "A category ('$category') was not found\n";
                  print MAIL "$committer\n$timestamp\n$action\n$description\n$category\n$port\n$entry\n";
                  close MAIL;
               } else {
                  $PortID = GetPortID($port, $categoryid, $dbh);

                  if ($PortID == 0) {
                     $PortID = PortCreate ($port, $categoryid, $timestamp, $description, $dbh);
                  }

                  if (!$Debug) {
                     $ChangePortID = ChangePortInsert($ChangeLogID, $PortID, $dbh);
                  }
                  print "ChangePortID = $ChangePortID\n";
               }

               #
               # save these values for next time!
               #
               print "adding '$category/$port' to the ports hash\n";
               $Ports{$category . "/" . $port} = [$PortID, $ChangePortID];
               if ($Ports{$category . "/" . $port}) {
                  print "I just checked, and yes, it's in the hash\n";
               } else {
                  print "I just checked, and it was not in the has.  This is SERIOUS.\n";
               }
            }

            if (!$Debug) {
               MarkPortAsRefreshNeeded($PortID, $ChangeLogID, $action, $entry, $dbh);
            }

            # by this point, ChangePortID and PortID are both assigned.  Time to put something into change_log_details
            if (!$Debug) {
               ChangeLogDetailInsert($ChangePortID, $PortID, $action, $entry, $dbh);
            }

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

#
# now we have completed process this message.  It's now time to refresh the ports which need refreshing.
#

print "now updating all the ports for that message\n";

my $NumPorts = 0;

while ((my $CategoryPort, my @PortIDChangePortID) = each %Ports) {
   $NumPorts++;

   print " looking at $CategoryPort ";
#   $PortID = $PortIDChangePortID[0];
   $PortID = $Ports{$CategoryPort}[0];

   print " which has a port id of $PortID\n";

   my $sql = "select needs_refresh from ports where id = $PortID";

   my $sth = $dbh->prepare($sql);
   $sth->execute ||
        die "Could not execute SQL $sql ... maybe invalid?";

   if (my @row=$sth->fetchrow_array) {
  
      my $NeedsRefresh = $row[0];

      if ($NeedsRefresh > 0) {
         ($category, $port) = split /\//,$CategoryPort, 2;

         print "about refresh $category, $port, $NeedsRefresh\n";

         RefreshOnePort($category, $port, $NeedsRefresh, $dbh);
      } else {
         print " ---- that port didn't need refreshing\n";
      }

   } else {
      #
      # well, we couldn't read that port.
      # it'd be nice if we could tell someone....
      #
      print "that read failed\n";
   }
}

if ($NumPorts) {
   print "number of ports updated by that message '$NumPorts'\n";
   #
   # make sure the daily summaries are up to date.
   # note: the timestamp thoughout one input is the same.
   # remember to supply only the YYYY/MM/DD part of the time stamp

   (my $DateOnly) = split/ /,$timestamp, 3;
   CreateDailySummary($DateOnly, $dbh);
} else  {
   print "no ports where updated by that message.  very strange.\n";
}

$dbh->disconnect();


#
# and let the www world know that the database has updated 
# and therefore their cache files are out of date
#
`touch /www/change.freshports.org/lastupdate`;
