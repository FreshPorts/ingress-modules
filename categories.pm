#
# Copyright (c) 2001-2026 Dan Langille
#

package FreshPorts::categories;

require FreshPorts::config;
require FreshPorts::utilities;

use strict;

# start with an empty array
# this is the list of valid categories according to the repo
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
	# Read the list again on every call.  observer_commits.pm reads it when
	# it loads, before the commit is checked out, and xml_munge_git.pm
	# calls this again once ScrollToThatCommit has the tree at that commit.
	# This used to return the list it already had, so the second call
	# changed nothing: a commit which added a category had the ports in
	# that new category skipped as "not an actual category".  The list is
	# one find(1) of the top of the ports tree, so reading it twice per
	# commit costs nothing worth saving.
	#
	my $this = shift;

	print "grabbing categories from disk\n";
	my $categories_1line = `$FreshPorts::Config::ScriptDir/get-list-of-current-categories.sh`;
	if ($?) {
		FreshPorts::Utilities::ReportErrorEmail('ERR', "could not get list of categories", 1, 1);
	}
	chomp $categories_1line;

	print "'$categories_1line'\n";

	@FreshPorts::Categories::categories = split / /, $categories_1line;

	# With no categories every ports file looks like it is outside a port,
	# so the commit would be saved without its ports.  Stop instead, so the
	# commit fails and goes to retry/ to be loaded again once the ports
	# tree is back.
	if (!@FreshPorts::Categories::categories) {
		FreshPorts::Utilities::ReportErrorEmail('ERR', "the list of categories is empty: is the ports tree missing or empty?", 1, 1);
	}

	return @FreshPorts::Categories::categories;
}

1;
