#
# $Id: observer_commits.pm,v 1.1.2.2 2004-09-17 03:14:56 dan Exp $
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

	if ($action eq $FreshPorts::Messages::FileUpdate) {
		print "Observer has noticed that commit '" . $object->id() . "' contains file $params{FilePath} as revision $params{FileRevision}\n";
		FreshPorts::SpecialProcessingFiles::Eat($dbh, $params{FileAction}, $params{FilePath}, $params{FileRevision});
	}

	if ($action eq $FreshPorts::Messages::PortsRefreshed) {
		print "Observer has noticed that ports for $params{message_id} have been refreshed.\n";
	}

	if ($action eq $FreshPorts::Messages::ProcessingDone) {
		print "Observer has noticed that processing has finished.\n";
	}
	if ($action eq $FreshPorts::Messages::PortsFreezeCheck) {
		print "Observer has noticed that we must do a ports freeze check.\n";
	}

}

1;
