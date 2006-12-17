#
# $Id: observer_commits.pm,v 1.2 2006-12-17 12:04:01 dan Exp $
#
# Copyright (c) 2004-2006 DVL Software
#

#
# These are the messages passed around between Observables and Observers

package FreshPorts::ObserverCommits;

use special_processing_files;

my %PortsCacheRemove;

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

	$this->{patching_needed}      = 0;
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
		print "Observer has noticed that commit '" . $object->id() . "' contains file $params{FilePath} as revision $params{FileRevision}\n";
		FreshPorts::SpecialProcessingFiles::Eat($class->{dbh}, $params{FileAction}, $params{FilePath}, $params{FileRevision});

		if ($params{FilePath} eq 'ports/Mk/bsd.port.mk') {
			Sys::Syslog::syslog('notice', "We'll need to patch because of $params{FilePath}");
			$class->{patching_needed} = 1;
		}
	}

	if ($action eq $FreshPorts::Messages::PortsRefreshed) {
		print "Observer has noticed that ports for $params{message_id} have been refreshed.\n";

		use ports_vulnerable;

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

	if ($action eq $FreshPorts::Messages::FilesFetched && $class->{patching_needed}) {
		`$FreshPorts::Config::scriptpath/patch-ports-infrastructure.sh`
	}


	if ($action eq $FreshPorts::Messages::UpdateEnds) {
		print "Observer has noticed that the update for $params{message_id} has finished.\n";

		print "Observer will clear the following items from cache after the commit:\n";
		
		my %CommitLogPorts = %{$params{CommitLogPorts}};

		while (my ($portname, $commit_log_ports) = each %CommitLogPorts) {
			$CommitLogPorts{$portname}	= $commit_log_ports;

			$port = $commit_log_ports->{port};
			print "$port->{category}/$port->{name}\n";
			
			$PortsCacheRemove{"$port->{category}/$port->{name}"}	= "$port->{category}/$port->{name}";
		}
		print "*** end of items to be cleared\n"
	}

	if ($action eq $FreshPorts::Messages::TransactionCommitted) {
		print "Observer has noticed that a transaction has been committed.\n";

		use caching;
		$Caching = FreshPorts::Caching->new($class->{dbh});
		$Caching->RemovePortsFromCache(\%PortsCacheRemove);
	}

}

1;
