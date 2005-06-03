#
# $Id: observer_commits.pm,v 1.1.2.6 2005-06-03 02:43:24 dan Exp $
#
# Copyright (c) 2004 DVL Software
#

#
# These are the messages passed around between Observables and Observers

package FreshPorts::ObserverCommits;

use special_processing_files;

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

	$this->{patching_needed} = 0;
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
	}

	if ($action eq $FreshPorts::Messages::PortsFreezeCheck) {
		print "Observer has noticed that we must do a ports freeze check.\n";
	}

	if ($action eq $FreshPorts::Messages::FilesFetched && $class->{patching_needed}) {
		`$FreshPorts::Config::scriptpath/patch-ports-infrastructure.sh`
	}

}

1;
