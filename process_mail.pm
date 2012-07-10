#!/usr/bin/perl -w
#
# $Id: process_mail.pm,v 1.1 2012-07-10 19:06:45 dan Exp $
#
# Copyright (c) 2001-2012  DVL Software
#
# helper functions for processing email
#

package FreshPorts::ProcessMail;

use strict;

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

1;
