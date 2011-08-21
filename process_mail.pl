#!/usr/bin/perl -w
#
# $Id: process_mail.pl,v 1.3 2011-08-21 19:36:15 dan Exp $
#
# Copyright (c) 2001-2003  DVL Software
#
# Process determine if this is cvs or svn email, and invoke the correct code.
# and convert it to XML output according to the FreshPorts DTD.
#

use strict;
use XML::Writer;
use constants;
use utilities;

&main;
exit;

#####
# Main Processing Routine
#####
sub main {
	# Get the message
	my ($message) = &myGetMessage;
	
	my $Message_Subject = &myGetMessage_Subject($message);


	
	# the message id uniquely identifies the email, and thus, the commit in question
	# the message id should be in one of two forms (given that we are processing stuff from just two lists):
	#  201108100855.p7A8tkQt033487@svn.freebsd.org     (SVN commit)
	#  201108101456.p7AEuU2o048428@repoman.freebsd.org (CVS commit)
	
	my $MessageId = &myGetMessage_Id($message);
	if (!defined($MessageId)) {
		FreshPorts::Utilities::ReportErrorEmailNoPrint('err', "No Message-Id found for this commit message (" . $Message_Subject . ").\n\nIs this a corrupted commit or email?", 1)
	}

	# the List Id helps to tell us which script is needed for processing this email
	# the values should be one of the following:
	# NOTE: there are not full values, but should match the first part of the string..	
	#  List-Id: CVS commit messages for the ports tree
	#  List-Id: CVS commit messages for the doc and www trees
	#  List-Id: "SVN commit messages for the entire src tree

	my $ListId = &myGetList_Id($message);
	if (!defined($ListId)) {
		FreshPorts::Utilities::ReportErrorEmailNoPrint('err', "No List-Id found for this commit message (" . $Message_Subject . ").\n\nIs this a corrupted commit or email?", 1)
	}

#	print 'Message-Id: ' . $MessageId       . "\n";
#	print 'List-Id: '    . $ListId          . "\n";
#	print 'Subject: '    . $Message_Subject . "\n";

	my $found = 0;	
	if ($MessageId =~ /\@svn.freebsd.org/i) {
		if ($ListId =~ /SVN commit messages for the entire src tree/i) {
			$found = 1;
#			print "we should invoke the SVN scripts here\n";
			eval "use process_svn_mail";
		}
	}

	if ($MessageId =~ /\@repoman.freebsd.org/i) {
		if ($ListId =~ /CVS commit messages for the ports tree/i ||
		    $ListId =~ /CVS commit messages for the doc and www trees/i ||
		    $ListId =~ /\*\*OBSOLETE\*\* CVS commit messages for the entire tree/i ||
		    $ListId =~ /CVS commit messages for the projects tree/i) {
			$found = 1;
#			print "we should invoke the CVS scripts here\n";
			eval "use process_cvs_mail";
		}
	}
	
	if (!$found) {
		FreshPorts::Utilities::ReportErrorEmailNoPrint('err', "This List-Id/Message-Id combination is not known to this script. List-Id='" . 
			$ListId . "' Message-Id='" . $MessageId . "'\n\nIs this a corrupted commit or email?", 1)
	}
    
	# Get the data
	my ($Data_ref) = &GetData($message);

	# Create the XML
	&WriteXML($Data_ref);

	# Done!  Woo woo!
	exit;
}

#####
# myGetMessage - Get the actual email from STDIN
#####
sub myGetMessage {
	my ($message);

	while (<>) {
		$message .= $_;
	}

	return $message;
}


sub myGetMessage_Id {
	my ($message) = @_;
	my ($Id);

	my (@lines) = split("\n", $message);

	for (@lines) {
		my ($line) = $_;

		if ($line =~ /^Message-Id:/i) {
			$line =~ /\<(.*?)\>/g;
			$Id = $1;
			last;
		} 
	}

	return $Id;
}

sub myGetList_Id {
	my ($message) = @_;
	my ($Id);

	my (@lines) = split("\n", $message);

	for (@lines) {
		my ($line) = $_;

		if ($line =~ /^List-Id:/i) {
			$line =~ /: (.*)/i;
			$Id = $1;
			last;
		} 
	}

	return $Id;
}

sub myGetMessage_Subject {
#
# This obtains the subject from the raw email.
# It assumes the email has this format or similar:
# Subject: cvs commit: CVSROOT modules ports/math Makefile ports/math/py-mpz
#          Makefile distinfo pkg-comment pkg-descr pkg-plist
#          ports/math/py-mpz/files setup.py
#
# 123456789
# This assumes 9 spaces there...
#

	my ($message) = @_;
	my ($Subject);

	my ($FoundSubject) = 0;

	my (@lines) = split("\n", $message);

	for (@lines) {
		my ($line) = $_;

		if ($FoundSubject) {
			if ($line =~ /^         /) {
				$Subject .= ' ' . (split/         /, $line, 2)[1];
				next;
			} else {
				last;
			}
		} else {
			if ($line =~ /^Subject:/i) {
				$Subject = (split/: /, $line, 2)[1];
				$FoundSubject = 1;
			}
		}
	}

	return $Subject;
}
