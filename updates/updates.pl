#!/usr/bin/perl

#
# Port Updater for FreshPorts
# takes output of LogMunger and updates the database
# written by Dan Langille
# copyright 2000 DVL Software
#

use DBI;
use strict;
use lib '/usr/local/etc/freshports/updates';
use ports;

my $Debug = 0;


# * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
# * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
# * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
# * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
#
# DO NOT MODIFY THE BELOW VALUES WITHOUT ALSO CHANGING THE SAME VALUES IN fetch-refresh-ports

my $FILE_MAKEFILE       = "Makefile";
my $FILE_DESCRIPTION    = "pkg-descr";
my $FILE_COMMENT        = "pkg-comment";
my $FILE_MAKEFILECOMMON = "Makefile.common";
my $FILE_MAKEFILEMAN    = "files/Makefile.man";

my %FilesWhichPromptRefresh = (
    $FILE_MAKEFILE       => "1",
    $FILE_DESCRIPTION    => "2",
    $FILE_COMMENT        => "4",
    $FILE_MAKEFILECOMMON => "8",
    $FILE_MAKEFILEMAN    => "16",
);

# DO NOT MODIFY THE ABOVE VALUES WITHOUT ALSO CHANGING THE SAME VALUES IN fetch-refresh-ports

# * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
# * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
# * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
# * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *

sub StripTimezone($) {
   my $timestamp = shift;

   my $date;
   my $time;
   ($date, $time) = split/ /,$timestamp,3;

   $timestamp = $date . " " . $time;

   return $timestamp;
}


#ChangeLogInsert($committer, $timestamp, $description, $dbh);
sub ChangeLogInsert($;$;$;$) {
   my $committer   = shift;
   my $timestamp   = shift;
   my $description = shift;
   my $dbh         = shift;

   print "%%%%%     ChangeLogInsert - 1 " . `date "+%Y-%m-%d %H:%M:%S"` . "\n";
   my $sql = "INSERT INTO change_log (commit_date, committer, update_description) \
           values ('$timestamp', " . $dbh->quote($committer) . ", " . $dbh->quote($description) . ")";

   print "%%%%%     ChangeLogInsert - 2 " . `date "+%Y-%m-%d %H:%M:%S"` . "\n";
   print "ChangeLogInsert sql => " . $sql . "\n";

   print "%%%%%     ChangeLogInsert - 3 " . `date "+%Y-%m-%d %H:%M:%S"` . "\n";
   my $sth = $dbh->prepare($sql);

   print "%%%%%     ChangeLogInsert - 4 " . `date "+%Y-%m-%d %H:%M:%S"` . "\n";
   $sth->execute ||
        die "Could not execute change_log SQL statement $sql ... maybe invalid?";

   print "%%%%%     ChangeLogInsert - 5 " . `date "+%Y-%m-%d %H:%M:%S"` . "\n";
   my $ChangeLogID = $sth->{'mysql_insertid'};

   print "%%%%%     ChangeLogInsert - 6 " . `date "+%Y-%m-%d %H:%M:%S"` . "\n";
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

   my $sql = "INSERT INTO change_log_details (change_log_port_id, change_type, details) \
                values ($ChangePortID, '$change_type', '$details')";

   print "ChangeLogDetailInsert sql is $sql\n";

   my $sth = $dbh->prepare($sql);

   $sth->execute ||
        die "Could not execute change_log_detail SQL statement $sql ... maybe invalid?";

   my $ChangeLogDetailID = $sth->{'mysql_insertid'};

   return $ChangeLogDetailID;
}

#PortCreate ($port, $category, $categoryid, $timestamp, $commitdescription, $dbh) {
sub PortCreate($;$;$;$;$;$) {
   my $port              = shift;
   my $category          = shift;
   my $categoryid        = shift;
   my $timestamp         = shift;
   my $commitdescription = shift;
   my $dbh               = shift;


   my $needs_refresh;

   $needs_refresh = GetNeedsRefreshForNewPort($category, $port);

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
           "'$timestamp', $needs_refresh, 'A', 'N', " . $dbh->quote($commitdescription) . ")";

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
      # only when the Makefile is removed do we actually delete the port
      if ($entry eq "Makefile") {
         $sql .= ", status = 'D'";
         #
         # if we are deleting a port, we don't need to refresh it.
         # we do this in case the port is already waiting for a refresh
         # when it is deleted.
         #
         $sql .= ", needs_refresh = 0";
      }
   } else {
      #
      # we aren't removing anything, we are adding or modifying
      #

      #
      # depending on what has changed, we need to take action accordingly
      # if we are removing a file, we definitely don't need to refresh.
      # that's because any file which prompts a refresh, and is removed
      # pretty much means the port is being deleted.
      #

      my $index = $FilesWhichPromptRefresh{$entry};
      if ($index) {
         # this *is* a file for which we must do a refresh.

         #
         # but we don't refresh if the port has been deleted.
         #
         $sql .= ", needs_refresh = needs_refresh | $index ";
         if ($StatusOriginal eq "D") {
            #
            # if we have a deleted port, and we just added one of
            # the items which prompts a refresh, we undelete the port.
            #
            $sql .= ", status = 'A'";
            #
            # problem: port is committed as net/FlowScan, then deleted
            # then added back in as net/flowscan.  mySQL is case insensitive.
            # but the fetch on cvs isn't.  Therefore we start getting stuff
            # for FlowScan, which is in the attic, not for flowscan, which isn't.
            # Solution: when a port is reactivated from being deleted, make
            # sure ALL the fields are updated with the current values.
            # in short, what's done for a NEW port should be done with this
            # resurrected port.
            #
            # Dan Langille 2001.3.26
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

#
# this would be a good place for a short loop and a sleep if it fails
#
my $dbh = DBI->connect('dbi:mysql:freshports','updater','xyzzy');
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


print "start  " . `date "+%Y-%m-%d %H:%M:%S"`;

my @file=<STDIN>;
close(STDIN);
chomp(@file);

for(my $i=0; $i<=$#file; $i++) {
   my $line = $file[$i];

   print "%%%%% - top of loop " . `date "+%Y-%m-%d %H:%M:%S"` . "\n";

   ($committer, $timestamp, $action, $filename, $description, $extra)=split/\|/,$line;

#  strip off the timezone from the timestamp
   $timestamp = StripTimezone($timestamp);   

   print "committer=", $committer, "\ntimestamp=", $timestamp, "\naction='",  $action, "'\nfilename=", $filename, "\ndescription=", $description, "\n";

   # split the file name into three parts.
   # $entry might have something like pkg-descr
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
         #
         # note that ports/<category>/pkg/COMMENT contains the description of the category.
         # we might want to pick that up one day.
         # Dan Langille 2001.03.26
         #
         if ((index($ignoredirs, $category) == -1) && ($port ne 'Makefile') && ($port ne 'pkg')) {
            #print '  ***';
            # we have a file in this port which is actually being updated.  Let's update the port.

            #
            # the first thing we do, if we haven't already done it, is insert an entry into
            # the change_log table.  We do this only once per commit.  Hence the !defined($ChangeLogID)
            #
            if (!defined($ChangeLogID)) {
               # insert main details into the change_log table.
               print "%%%%% - inserting into change_log " . `date "+%Y-%m-%d %H:%M:%S"` . "\n";
               if (!$Debug) {
                  $ChangeLogID = ChangeLogInsert($committer, $timestamp, $description, $dbh);
               }
               print "change log ID is $ChangeLogID\n";
               print "%%%%% - after insert into change_log " . `date "+%Y-%m-%d %H:%M:%S"` . "\n";
            }
            print "change log ID is still $ChangeLogID\n";

            if ($Ports{$category . "/" . $port}) {
               print "ahhh, I see we've processed this port already...\n";
               # we've processed something for this port before

               # so get the PortID and ChangePortID
               $PortID       = $Ports{$category . "/" . $port}[0];
               $ChangePortID = $Ports{$category . "/" . $port}[1];
            } else {
               print "%%%%% - getting category " . `date "+%Y-%m-%d %H:%M:%S"` . "\n";

               print "this port ('$category/$port') was not found in the hash table\n";
               $categoryid = GetPortCategory($category, $dbh);

               print "%%%%% - after category " . `date "+%Y-%m-%d %H:%M:%S"` . "\n";
               if ($categoryid == '') {
                  # email the main man
                  open  MAIL, "|mail -s 'freshports notice' $NotifyByMail";
                  print MAIL "A category ('$category') was not found\n";
                  print MAIL "$committer\n$timestamp\n$action\n$description\n$category\n$port\n$entry\n";
                  close MAIL;

                  #
                  # the category was not found.  Let's create a new primary category.
                  #
                  $categoryid = CreateCategory("FreeBSD", $category, "", "Y", $dbh);
               }

               if ($categoryid == '') {
                  #
                  # hmmm, still not found.  This is a problem.
                  # email the main man
                  #
                  open  MAIL, "|mail -s 'freshports notice' $NotifyByMail";
                  print MAIL "Category ('$category') was created\n";
                  print MAIL "$committer\n$timestamp\n$action\n$description\n$category\n$port\n$entry\n";
                  close MAIL;
               } else {
                  print "%%%%% - getting port id " . `date "+%Y-%m-%d %H:%M:%S"` . "\n";

                  $PortID = GetPortID($port, $categoryid, $dbh);

                  print "%%%%% - got port id " . `date "+%Y-%m-%d %H:%M:%S"` . "\n";

                  if ($PortID == 0) {
                     print "%%%%% - creating port " . `date "+%Y-%m-%d %H:%M:%S"` . "\n";

                     $PortID = PortCreate ($port, $category, $categoryid, $timestamp, $description, $dbh);

                     print "%%%%% - port created " . `date "+%Y-%m-%d %H:%M:%S"` . "\n";
                  }

                  if (!$Debug) {
                     print "%%%%% - change port insert " . `date "+%Y-%m-%d %H:%M:%S"` . "\n";

                     $ChangePortID = ChangePortInsert($ChangeLogID, $PortID, $dbh);

                     print "%%%%% - change port inserted " . `date "+%Y-%m-%d %H:%M:%S"` . "\n";
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
               print "%%%%% - marking refresh " . `date "+%Y-%m-%d %H:%M:%S"` . "\n";

               MarkPortAsRefreshNeeded($PortID, $ChangeLogID, $action, $entry, $dbh);

               print "%%%%% - refresh marked " . `date "+%Y-%m-%d %H:%M:%S"` . "\n";
            }

            # by this point, ChangePortID and PortID are both assigned.  Time to put something into change_log_details
            if (!$Debug) {
               print "%%%%% - change_log_detail insert " . `date "+%Y-%m-%d %H:%M:%S"` . "\n";
               ChangeLogDetailInsert($ChangePortID, $PortID, $action, $entry, $dbh);
               print "%%%%% - change_log_detail insert " . `date "+%Y-%m-%d %H:%M:%S"` . "\n";
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
# now we have processed this message.  It's now time to refresh the ports which need refreshing.
#

print "now updating all the ports for that message\n";

my $NumPorts = 0;

print "%%%%% - starting main loop " . `date "+%Y-%m-%d %H:%M:%S"` . "\n";
while ((my $CategoryPort, my @PortIDChangePortID) = each %Ports) {
   $NumPorts++;

   print " looking at $CategoryPort ";

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

         print "%%%%% - refreshing $category/$port " . `date "+%Y-%m-%d %H:%M:%S"` . "\n";

         RefreshOnePort($category, $port, $NeedsRefresh, $dbh);

         print "%%%%% - refreshed $category/$port " . `date "+%Y-%m-%d %H:%M:%S"` . "\n";
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

print "%%%%% - main loop done " . `date "+%Y-%m-%d %H:%M:%S"` . "\n";

if ($NumPorts) {
   print "number of ports updated by that message '$NumPorts'\n";
   #
   # make sure the daily summaries are up to date.
   # note: the timestamp thoughout one input is the same.
   # remember to supply only the YYYY/MM/DD part of the time stamp

   (my $DateOnly) = split/ /,$timestamp, 3;
   print "%%%%% - creating daily summary " . `date "+%Y-%m-%d %H:%M:%S"` . "\n";

   CreateDailySummary($DateOnly, $dbh);

   print "%%%%% - daily summary done " . `date "+%Y-%m-%d %H:%M:%S"` . "\n";

} else  {
   print "no ports where updated by that message.  very strange.\n";
}

$dbh->disconnect();


#
# and let the www world know that the database has updated 
# and therefore their cache files are out of date
#
`touch /home/freshports.org/scripts/lastupdate`;

print "finish " . `date "+%Y-%m-%d %H:%M:%S"`;
