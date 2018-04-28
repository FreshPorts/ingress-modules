#
# $Id: observer_commits.pm,v 1.6 2012-10-23 16:31:04 dan Exp $
#
# Copyright (c) 2004-2006 DVL Software
#

#
# These are the messages passed around between Observables and Observers

package FreshPorts::ObserverCommits;

use FreshPorts::special_processing_files;

my %PortsCacheRemove;
my %FilesCacheRemove;

sub new {
	my $this		= {};
	my $class		= shift;

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
			$CommitLogPorts{$portname}	= $commit_log_ports;

			$port = $commit_log_ports->{port};
			print "$port->{category}/$port->{name}\n";
			
			$PortsCacheRemove{"$port->{category}/$port->{name}"}	= "$port->{category}/$port->{name}";
		}

		print "Observer will clear the following files from cache after the commit:\n";
		my @Files = @{$params{Files}};
		foreach $value (@Files) {
			my ($action, $filename, $revision, $commit_log_element_id, $element_id) = @$value;
			my ($subtree, $category_name, $port_name, $extra) = split/\//,$filename, 4;

			# look for special files outside a port, such as LEGAL, GIDs, UIDs
			if ($subtree eq $FreshPorts::Config::ports_prefix && defined($FreshPorts::Constants::IgnoredItems{$category_name})) {
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
		$Caching->RemovePortsFromCache(\%PortsCacheRemove);
		$Caching->RemoveFilesFromCache(\%FilesCacheRemove);
	}

}

1;
