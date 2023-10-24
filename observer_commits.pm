#!/usr/local/bin/perl -w
#
# Copyright (c) 2004-2006 DVL Software
#

#
# These are the messages passed around between Observables and Observers

package FreshPorts::ObserverCommits;

use FreshPorts::special_processing_files;
use FreshPorts::categories;

use List::MoreUtils 'any';

my %PortsCacheRemove;
my %FilesCacheRemove;

sub new {
	my $this	= {};
	my $class	= shift;

	$this->{dbh}	= shift;

	bless $this;

	$this->_initialize();

	return $this;
}

sub _initialize {
	my $this = shift;

	$this->{cache_refresh_needed} = 0;
}

sub update {
	my ( $class, $object, $action, %params) = @_;
	unless ( $action ) {
		warn "Cannot operation on [", $object->id, "] without action";
		return;
	}

	if ($action eq $FreshPorts::Messages::ProcessingBegins) {
		print "Observer has noticed that processing has begun.\n";
	}

	if ($action eq $FreshPorts::Messages::CommitSaved) {
		print "Observer has noticed that commit '" . $object->id() . "' has been saved with a commit log id of $params{commit_log_id}.  Thank you.\n";
		$this->{cache_refresh_needed} = 1;
	}

	#
	# NOTE: we now do this during the File Update.
	# I think we should do this after the file fetch.
	# That way, script processing will not attempt to run
	# through a file that is not yet fetched, or worse still,
	# is being fetched.
	#
	if ($action eq $FreshPorts::Messages::FileUpdate) {
		print "Observer has noticed that commit '" . $object->id() . "' contains file $params{FilePath} as revision $params{FileRevision} in repository $params{Repository}\n";
		FreshPorts::SpecialProcessingFiles::Eat($class->{dbh}, $params{FileAction}, $params{FilePath}, $params{FileRevision}, $params{Repository});
	}

	if ($action eq $FreshPorts::Messages::PortsRefreshed) {
		print "Observer has noticed that ports for $params{message_id} have been refreshed.\n";

		use FreshPorts::ports_vulnerable;

		$PV = FreshPorts::PortsVulnerable->new($class->{dbh});
		$PV->PortsVulnerabilityCountAdjust($params{CommitLogPorts});
	}

	if ($action eq $FreshPorts::Messages::ProcessingDone) {
		print "Observer has noticed that processing has finished.\n";
		if ($this->{cache_refresh_needed}) {
			`/usr/bin/touch $FreshPorts::Config::RefreshCachFileFlag`;
		}
	}

	if ($action eq $FreshPorts::Messages::PortsFreezeCheck) {
		print "Observer has noticed that we must do a ports freeze check.\n";
	}

	if ($action eq $FreshPorts::Messages::UpdateEnds) {
		print "Observer has noticed that the update for $params{message_id} has finished.\n";

		print "Observer will clear the following ports from cache after the commit:\n";
		
		my %CommitLogPorts = %{$params{CommitLogPorts}};

		while (my ($portname, $commit_log_ports) = each %CommitLogPorts) {
			$CommitLogPorts{$portname} = $commit_log_ports;

			$port = $commit_log_ports->{port};
			print "$port->{category}/$port->{name}\n";
			
			$PortsCacheRemove{"$port->{category}/$port->{name}"} = "$port->{category}/$port->{name}";
		}

		print "Observer will clear the following files from cache after the commit:\n";

		# declare these first
		my ($null, $subtree, $head, $branches, $category_name, $port_name, $extra);

		# For /ports/head/net/openmpi3/files/patch-opal_mca_pmix_pmix2x_pmix_src_mca_pshmem_mmap_pshmem__mmap.c for cache clearinge, we'd get:
		# null          = ''
		# subtree       = 'ports'
		# head          = 'head'
		# category_name = 'net'
		# port_name     = 'openmpi3'
		# extras        = 'files/patch-opal_mca_pmix_pmix2x_pmix_src_mca_pshmem_mmap_pshmem__mmap.c'
		#
		# For /ports/branches/2023Q4/net/traefik/Makefile, we'd get:
		# null          = ''
		# subtree       = 'ports'
		# branches      = 'branches'
		# branch        = '2023Q4'
		# category_name = 'net'
		# port_name     = 'traefik'
		# extras        = 'Makefile'

		my @Files = @{$params{Files}};
		foreach $value (@Files) {
			my ($action, $filename, $revision, $commit_log_element_id, $element_id) = @$value;

			# if we're on head, we figure out the path components differently than on a branch
			$on_head = $filename =~ m/^$FreshPorts::Constants::Ports_HEAD_commit/;

			# see above for a breakdown on what this does
			# because the path always starts with a leading /, the first component pulled out is always an empty string
			if ($on_head) {
				($null, $subtree, $head, $category_name, $extra) = split/\//,$filename, 5;
			} else {
				($null, $subtree, $branches, $branch, $category_name, $extra) = split/\//,$filename, 6;
			}

#			print "checking category: '$category_name'\n";

			# This decides what to clear from cache and what to ignore, because it is not cached, or will be cleared
			# when a 'parent' item is cleared. e.g. sysutils/anvil/Makefile will get cleared when sysutils/anvil is
			# cleared.
			# We want anything which is not a category
			# If we have a port in this commit, the category is already cleared
			# so anything in a category can be ignored.
			# We are looking for stuff which is not under a category.
			# We might not get a category, e.g. /base/head/ObsoleteFiles.inc in ae5c3dfd3e75bb287984947359d4f958aea505ec
			# FreshPorts does not provided access to individual history for src and www. The data is there. The website
			# just does not parse the incoming URI to see if thats what is being requested. It checks only for ports.
			#
			if ( defined($category_name) && ! any {/$category_name/} @FreshPorts::Categories::categories ) {
				# take a copy of that filename and remove the subtree prefix. Add that to the queue for removal
				my $FileCacheItem = $filename;
				$FileCacheItem =~ s|^$FreshPorts::Config::ports_prefix/||g;
				$FilesCacheRemove{"$FileCacheItem"}	= "$FileCacheItem";
				print "$FileCacheItem\n";
			}
			else
			{
				print "we are ignoring $filename for cache clearing\n";
			}
		}
		print "*** end of items to be cleared\n"
	}

	if ($action eq $FreshPorts::Messages::TransactionCommitted) {
		print "Observer has noticed that a transaction has been committed.\n";

		use FreshPorts::caching;
		$Caching = FreshPorts::Caching->new($class->{dbh});
#		$Caching->RemovePortsFromCache(\%PortsCacheRemove);  # I suspect this call can be dropped. The code is a NOP
		$Caching->RemoveFilesFromCache(\%FilesCacheRemove);

		# we have to commit because we are separate - the main commit has already occurred.
        $sth = $class->{dbh}->prepare("commit");
        $sth->execute ||
            die "Could not execute SQL $sql ... maybe invalid?";
	}

}

FreshPorts::categories::FetchAll();

1;
