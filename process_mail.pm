#!/usr/bin/perl -w
#
# $Id: process_mail.pm,v 1.3 2012-10-23 16:31:04 dan Exp $
#
# Copyright (c) 2001-2012  DVL Software
#
# helper functions for processing email
#

package FreshPorts::ProcessMail;

use strict;
use Email::MIME;

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
    my ($encoding);

    while (<>) {
        $message .= $_;
    }

    $encoding = myGetMessage_ContentTransferEncoding($message);
#    print $encoding  . "\n";

    if ($encoding eq 'base64')
    {
        # we need to extract the body from this message, base64 decode it, and go from there...
        my $parsed = Email::MIME->new($message);
        my $content_type = $parsed->content_type;
        
        $parsed->body_set($parsed->body);

        my $header = $parsed->header_obj;
        $message = $header->as_string . $parsed->body_str;

    }

    return $message;
}

sub myGetMessage_ContentTransferEncoding {
	my ($message) = @_;
	my ($encoding);

	my (@lines) = split("\n", $message);

	for (@lines) {
		my ($line) = $_;

		if ($line =~ /^Content-Transfer-Encoding:/i) {
			$line =~ /^Content-Transfer-Encoding: (.*)/g;
			$encoding = $1;
			last;
		} 
	}

	return $encoding;
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
