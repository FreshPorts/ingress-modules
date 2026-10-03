#!/usr/local/bin/perl -w
#
# $Id: process_mail.pm,v 1.4 2012-11-01 00:54:56 dan Exp $
#
# Copyright (c) 2001-2026 Dan Langille
#
# helper functions for processing email
#

package FreshPorts::ProcessMail;

use strict;
use Email::MIME;
use Text::Unidecode;

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
        # we decode to avoid UTF-8 characters... we want only ASCII
        $message = unidecode($header->as_string . $parsed->body_str);

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
	my ($message) = @_;
	my ($Subject);

	my %arg;
	my $email = Email::Simple->new($message, \%arg);
	$Subject = $email->header("Subject");

	return $Subject;
}

1;
