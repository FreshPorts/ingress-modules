#!/usr/local/bin/perl

my $FILE_MAKEFILE       = "Makefile";
my $FILE_DESCRIPTION    = "pkg-descr";
my $FILE_COMMENT        = "pkg-comment";
my $FILE_MAKEFILECOMMON = "Makefile.common";
my $FILE_MAKEFILEMAN    = "files/Makefile.man";

my %FilesWhichPromptRefresh = (
    $FILE_MAKEFILE       => 1,
    $FILE_DESCRIPTION    => 2,
    $FILE_COMMENT        => 4,
    $FILE_MAKEFILECOMMON => 8,
    $FILE_MAKEFILEMAN    => 16,
);

$needs_refresh = "1";

  while ((my $key, my $value) = each %FilesWhichPromptRefresh) {
      if ($needs_refresh & $value) {
         print "now fetching $key\n";
      }
  }




