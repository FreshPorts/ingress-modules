#!/usr/bin/perl

package	ports;
require	Exporter;
@ISA	= qw(Exporter);
@EXPORT	= qw(PortUpdate ExtractCategoryFromDirectory GetDescrAndHomePage ReadFile PackageExists);
 
#
# this script should walk the ports tree and update the 
# ports table accordingly.
#

# =================================    
sub ExtractCategoryFromDirectory($) {

   my $dir = shift;

print "directory = $dir\n";

   # split the dir into separate elements
   my @fields = split(/\//, $dir);

   #grab the last one.
   my $category = @fields[$#fields];

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
      if(/$package/) {
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
                                                                
   @result = ($DESCR, $url);                                    
                                                                
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

#sub GetPortCategory($category, $dbh) {
sub GetPortCategory($;$) {
   my $category = shift;
   my $dbh = shift;

   my $sql = "select id from categories where name = '" . $category . "'";

   print "\n",$sql, "\n";

   my $sth = $dbh->prepare($sql);

   $sth->execute ||
        die "Could not execute SQL statement ... maybe invalid?";


   my @row=$sth->fetchrow_array;

   print "\nGetPortCategory = $sql which gives ", @row[0], "\n";

   return @row[0];
}

sub PortUpdate($;$;$;$;$;$;$;$;$;$;$;$;$;$;$;$;$) {
#PortUpdate ($name, $portname, $category, $descrfile, $categories, $portversion, 
#          $commentfile, $maintainer, $extractsuffix, $mastersites, $builddepends,
#    $rundepends, $shortdescription, $longdescription, $homepage, $packageexists, $dbh);

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
   my $dbh              = shift;


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
print "13 $homepage\n";
print "14 $packageexists\n";

# this asks for user input
#<STDIN>;

#return;

   my $categoryid = GetPortCategory($category, $dbh);
   if (!$categoryid) {
      print "ERROR *** could not find category for $category\n";
      exit;
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
      $sql = "insert into ports (name, description,                                                       \
              primary_category_id, system, version, date_created,                                         \
              short_description, long_description, maintainer, categories,                                \
              date_last_refreshed, needs_refresh, homepage, master_sites, extract_suffix, package_exists, \
              status, depends_run, depends_build) values (";

      $sql .= "'$name', '$descpath', $categoryid ,                                        \
              'FreeBSD', '$portversion', current_timestamp, '$shortdescription',          \ 
              '$longdescription', '$maintainer', '$categories', current_timestamp, 'N',   \
              '$homepage', '$mastersites', '$extractsuffix', '$packageexists', 'A',       \
              '$rundepends', '$builddepends')";

      print "$sql\n";

      $sth = $dbh->prepare($sql);

      $sth->execute ||
         die "Could not insert statement ... maybe invalid?";
   } else {
      # update the time on the port
      $sql = "update ports set description = '$descpath',       \ 
              version = '$portversion', short_description = \
              '$shortdescription', long_description = '$longdescription', maintainer = \
              '$maintainer', categories = '$categories', date_last_refreshed = \
              current_timestamp, homepage = '$homepage', master_sites = '$mastersites', \
              extract_suffix = '$extractsuffix', package_exists = '$packageexists', status \
              = 'N', needs_refresh = 'N', depends_run = '$rundepends', depends_build = '$builddepends' \
              where id = $row[0]";

      print "$sql\n";

      $sth = $dbh->prepare($sql);

      $sth->execute ||
         die "Could not execute update statement ... maybe invalid?";
   }
}


