#!/usr/local/bin/perl -w

use strict;
use portschange;
 
use DBI;

my $result = 0;

if (($#ARGV+1) == 3) {
   print "there are 3 arguments\n";
   my $portid        = $ARGV[0];
   my $category      = $ARGV[1];
   my $port          = $ARGV[2];

   my $needs_refresh;
   my @row;
   my $sql;
   my $sth;

   my $dbh = DBI->connect('dbi:mysql:freshportschange','root','xyzzy');

   if ($dbh) {
      
      $sql = "select needs_refresh \
              from ports \
              where ports.id       = $portid";

      $sth = $dbh->prepare($sql);
      $sth->execute ||
              die "Could not execute SQL $sql ... maybe invalid?";

      @row=$sth->fetchrow_array;
      $needs_refresh = $row[0];

      $sth->finish;

      if ($needs_refresh) {
         $result = RefreshOnePort($category, $port, $needs_refresh, $dbh);
      }

      $dbh->disconnect();
   
      if ($needs_refresh && $result == 0) {
         `touch /usr/local/etc/freshports/msgs/lastupdate`
      }
   }
} else {
   print "usage : PORTID CATEGORY PORT\n";
}
