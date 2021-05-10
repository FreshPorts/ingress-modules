#
# Copyright (c) 2001-2021 DVL Software
#

package FreshPorts::categories;

require FreshPorts::config;

use strict;

# start wtih an empty array
@FreshPorts::Categories::categories = ();

# =================================

sub _initialize {
	my $this    = {};
	my $class   = shift;

	# always make sure we are fully loaded
	bless $this;
	$this->FetchAll();
}

# =================================

sub new {
	my $this    = {};
	my $class   = shift;

	bless $this;
	$this->_initialize();
	return $this;
}

sub FetchAll {
	#
	# return an array containing one entry for each category as obtained from the repo
	#
	my $this = shift;
	
	if (@FreshPorts::Categories::categories != 0) {
		print "categories already loaded\n";
		return @FreshPorts::Categories::categories;
	}
	
	print "grabbing categories from disk\n";
	my $categories_1line = `$FreshPorts::Config::ScriptDir/get-list-of-current-categories.sh`;
	chomp $categories_1line;

	#print "'$categories_1line'\n";

	@FreshPorts::Categories::categories = split / /, $categories_1line;

	return @FreshPorts::Categories::categories;
}

1;
