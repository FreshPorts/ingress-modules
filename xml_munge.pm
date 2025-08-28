#!/usr/local/bin/perl
# 
# $Id: xml_munge.pm,v 1.18 2012-10-23 16:31:04 dan Exp $
#
# Copyright (c) 2001-2006 DVL Software
#
# Parse cvs messages in XML format so they can be put into a database
# Version 4 - uses DTD version 0.12
#
#
# return values
#  1 - incorrect calling of script.  check your parameters
#  2 - this message id is already in the database
#  3 - No SystemID found for OS  - this OS     isn't being followed by FreshPorts
#  4 - No SystemBranchID found   - this branch isn't being followed by FreshPorts
#  5 - invalid file action found - the file action found wasn't recognized. Check the DTD.
#  6 - element id was not found  - possible problem adding new element to database.
#  7 - this messages does not deal with the ports subsystem.
#

# we make a great deal of use of a global variable Updates.  We should fix that up.
#


# use strict;


package FreshPorts::XML_Munge;

require Sys::Syslog;

use FreshPorts::utilities;

use XML::Node;


my $debug                   = 0;

my $_RollbackNeeded         = 0;  # set by Rollback_Needed()

#
# a file can be added to the repository, deleted (removed) from the repository,
# or modified in the repository.
#
my %Updates;

my $self;	# for use by functions that cannot get this value (i.e. handler_*)

sub new {
	my $this     = {};
	my $class    = shift;

	bless $this;

	$this->_initialize();

	return $this
}


sub _initialize {
	my $this = shift;
	
	$Updates{Source} = '';

	# save self for use by function that cannot get access to it.
	$self = $this
}	


sub process {
	my ( $this ) = @_;

	$this->main;

	return $_RollbackNeeded;
}

sub usage {
	my $this = shift;

	print "USAGE : $0 INPUTFILE [-D]\n";
	print "   -D : debug\n";
}

#####
# Main Processing Routine
##### 

sub main {
	my $this = shift;

	my $p = XML::Node->new();

	if (($#ARGV+1) >= 1) {
		$inputfile = $ARGV[0];
		if (-f $inputfile) {
		} else {
			print "please specify an input file name which exists\n";
			exit 1;
		}
		my $i;

		for ($i = 1; $i < ($#ARGV+1); $i++) {
			print "checking arg $i\n";
			if ($ARGV[$i] eq '-D') {
				print "debugging....\n";
				$debug = 1;
				next;
			}

			# we have found arguments we know nothing about
			print 'unknown argument ' . $ARGV[$i] . "\n";
			$this->usage();
			exit 1;
		}
	} else {
		usage();
		exit 1;
	}

	$this->SetupParser($p);

	print "Processing file [$inputfile]...\n";

	print "parsing file now\n";

	$p->parsefile($inputfile);
}

sub SetupParser($) {
	my $this = shift;

	my $p = shift;

	$p->register(">UPDATES",         "start" => \&handle_updates_start);
	$p->register(">UPDATES:Version", "attr"  => \$Updates{Version});
	$p->register(">UPDATES:Source",  "attr"  => \$Updates{Source});

	$p->register(">UPDATES",         "end"   => \&handle_updates_end);

	print "finished setting up the Parser\n";
}

sub handle_updates_start {
	print "\n\n *** start of all updates ***\n";
}

	
sub handle_updates_end {
	print "\n\n *** end of all updates *** \n";
}

sub getSource {
	my $this = shift;
	
	print "source in getSource is '$Updates{Source}'\n";
	
	return $Updates{Source};
}

1;
