#!/usr/bin/perl -w
#
# $Id: process_svn_mail.pm,v 1.9 2012-10-26 15:22:15 dan Exp $
#
# Copyright (c) 2001-2003  DVL Software
#
# Process incoming mail from cvs-all mailing list at freebsd.org
# and convert it to XML output according to the FreshPorts DTD.
#

use strict;
use Date::Parse;
use XML::Writer;
use constants;
use utilities;
use process_mail;

#####
# GetMessage - Get the actual email from STDIN
#####
sub GetMessage {
	my ($message);

	while (<>) {
		$message .= $_;
	}

	return $message;
}

#####
# GetData - Generate and return the data structure
#####
sub GetData {
	my ($message) = shift;
	my (@Data);

	my $Message_Subject;
	my $Log;
	my $EncodingLosses = 'false';
	
	# FreeBSD uses multiple repos.  One for each of doc, src, and ports.  We store all commits in one database.
	# so we prefix each pathname with the repo prefix.
	my $RepoPrefix;
	
	$Message_Subject = &GetMessage_Subject($message);

#print "subject: '$Message_Subject'\n";

	$Log = &GetLog($message);
	
#print "log: '$Log'\n";

	if ($Log eq '') {
		$Log = $Message_Subject;
	}

	my $MessageID = &GetMessage_Id($message);
	if (!defined($MessageID)) {
		FreshPorts::Utilities::ReportErrorEmailNoPrint('err', "No message ID found for this commit message (" . $Message_Subject . ").\n\nIs this a corrupted commit or email?", 1)
	}

	# this is prefixed to all pathnames in this commit	
	$RepoPrefix = &GetOS_RepoPrefix($message);

	@Data =	[	'UPDATES', [ { Version => '1.3.2.1' },
				'UPDATE', [ {},
					'DATE', [ &GetDate($message)
					],
					'TIME', [ &GetTime($message)
					],
					'OS', [ {
						Id     => &GetOS_Id    ($message),
						Branch => &GetOS_Branch($message),
						Repo   => $RepoPrefix }
					],
					'LOG', [ {},
						0,
						$Log
					],
					'PEOPLE', [ {},
						&GetPeople($message)
					],
					'MESSAGE', [ {
						Id             => $MessageID,
						Subject        => $Message_Subject,
						EncodingLosses => $EncodingLosses },
						'DATE', [ &GetMessage_Date($message)
						],
						'TIME', [ &GetMessage_Time($message)
						],
						'REPOSITORY', [ {}, 0, $RepoPrefix
						],
						'REVISION', [ {}, 0, &GetRevision($message)
						],
						&GetMessage_To($message)
					],
					'FILES', [ {},
						&GetFiles($message)
					]
				]
			 ]
		];

	my ($PR) = &GetPR($message);
	if ($PR) {
		push @{$Data[0]->[1][2]}, 'PR', [ { Id => $PR } ];
	}

	return @Data;
}

#####
# WriteXML - Convert the data into XML and print
#####
sub WriteXML {
	my ($data_ref) = shift;

	my $output = '';
	# Use XML::Writer to create the XML
	my ($writer) = new XML::Writer( OUTPUT      => $output,
					DATA_INDENT => 4,
					DATA_MODE   => 1 );

	# Add the main XML tag
	$writer->xmlDecl("ISO-8859-1");

	# Add the XML Document Type
	$writer->doctype('UPDATES','-//FreshPorts//DTD FreshPorts 2.0//EN', 'http://www.freshports.org/docs/fp-updates.dtd');

	# Convert the data into XML
	&DataToXML($writer, $data_ref); 

	# No more XML
	$writer->end;
}

#####
# DataToXML - Convert the data into XML; tends to call itself
#####
sub DataToXML {
	my ($writer)   = shift;
	my ($data_ref) = shift;

	my ($count) = $#{$data_ref};
	for (my ($i) = 0; $i < $count; $i += 2) {
		my ($element_name)		= shift @{$data_ref};
		my ($element_content)	= shift @{$data_ref};

#print "element_name='$element_name'\n";

		if ($element_name eq '0') {
#			print 'HERE WE ARE!';
			$writer->characters($element_content);
		} else {
			my ($element_attributes) = shift @{$element_content};

			$writer->startTag($element_name, %$element_attributes);
			&DataToXML($writer, $element_content);
			$writer->endTag($element_name);
		}
	}
}
####################################################################
##### Functions to actually retrieve the data from the message #####
####################################################################

sub GetPR {
	my ($message) = @_;
	my ($PR);

	my (@lines) = split("\n", $message);
		
	for (@lines) {          
		my ($line) = $_;
	   
		if ($line =~ /^  PR:/i) {
			$PR = (split(" ", $line, 2))[1];
			last;
		}
	}

	return $PR;
}

sub GetPeople {
	my ($message) = shift;
	my (@people);

	push @people, 'UPDATER', [ { Handle => &GetUpdater_Handle($message) } ];

	my ($submitter) = &GetSubmitter($message);
	if ($submitter) {
		push @people, 'SUBMITTER', [ {}, 0, $submitter ];
	}

	my ($reviewer) = &GetReviewer($message);
	if ($reviewer) {
		push @people, 'REVIEWER', [ {}, 0, $reviewer ];
	}

	my ($approver) = &GetApprover($message);
	if ($approver) {
		push @people, 'APPROVER', [ {}, 0, $approver ];
	}

	my ($obtainedfrom) = &GetObtainedFrom($message);
	if ($obtainedfrom) {
		push @people, 'OBTAINEDFROM', [ {}, 0, $obtainedfrom ];
	}

	return @people;
}


sub GetObtainedFrom {
	my ($message) = @_;
	my ($ObtainedFrom);

	my (@lines) = split("\n", $message);
		
	for (@lines) {          
		my ($line) = $_;
	   
		if ($line =~ /^  Obtained from:/i) {
			$ObtainedFrom = (split(" ", $line, 3))[2];
			last;
		}
	}

	return $ObtainedFrom;
}

sub GetRevision {
	my ($message) = @_;
	my ($Revision);

	my (@lines) = split("\n", $message);
		
	for (@lines) {          
		my ($line) = $_;
	   
		if ($line =~ /^New Revision:/i) {
			$Revision = (split(" ", $line, 3))[2];
			last;
		}
	}

	return $Revision;
}


sub GetApprover {
	my ($message) = @_;
	my ($Approver);

	my (@lines) = split("\n", $message);
		
	for (@lines) {          
		my ($line) = $_;
	   
		if ($line =~ /^  Approved by:/i) {
			$Approver = (split(" ", $line, 3))[2];
			last;
		}
	}

	return $Approver;
}

sub GetReviewer { 
	my ($message) = @_;
	my ($Reviewer);

	my (@lines) = split("\n", $message);

	for (@lines) {
		my ($line) = $_;
		
		if ($line =~ /^  Reviewed by:/i) {
			$Reviewer = (split(" ", $line, 3))[2];
			last;
		}
	}

	return $Reviewer;
}

sub GetSubmitter {  
	my ($message) = @_;
	my ($Submitter);
		
	my (@lines) = split("\n", $message); 
				 
	for (@lines) {
		my ($line) = $_;
		
		if ($line =~ /^  Submitted by:/i) {
			$Submitter = (split(" ", $line, 3))[2];
			last;
		}
	}
		 
	return $Submitter;
}

sub IsDirectoryProvided($) {
#
# see whether or not we have a directory on this incoming $line.
# we assume that if the first 20 characters are all blanks,
# there is no directory.


	my ($line) = shift;

	my ($dir) = substr($line, 0, 20);
	$dir =~ s/\s*$//;                                       

	#
	# if non-zero, there's a directory.  otherwise, none.
	#
	return length($dir)
}
 
sub GetFiles {
	my ($message)    = shift;
	my ($RepoPrefix) = shift;
	my (@files);
	my ($revision, $action, $path);
	my (@lines) = split("\n", $message);

	# Modified Files
	my ($found) = 0;
	for (@lines) {
		my ($line) = $_;

		$revision = $1 if (/New Revision:\s+(\d+)/);

		#
		# see also GetLog for use of Revision.
		#
		if ($line =~ /^Modified:/) { 
			$found = 1; 
			$action = $FreshPorts::Constants::MODIFY;
			next;
		}
		elsif ($line =~ /^Added:/) { 
			$found = 1; 
			$action = $FreshPorts::Constants::ADD;
			next;
		}
		elsif ($line =~ /^Deleted:/) { 
			$found = 1; 
			$action = $FreshPorts::Constants::REMOVE;
			next;
		}
		next unless $found == 1;
		$path = $line;
		next if($path =~ /\s+-\s+/); # skip messages about file origin

		# we always ignore stuff after these lines		
		# we always ignore stuff after these lines              
		last if($line =~ /^Directory Properties:/);
		last if($line =~ /^Changes in other areas also in this revision::/);
		
#		# this removes head/, stable/ or vendor/ from the path
#		# we may need to revist this if ports start commiting on non-head
#		$path =~ s/^\s+(head\/|stable\/\d+\/|vendor\/)//;

#print "still looking at '$line'\n";
		# stop on either action change, empty string or minimalist signature 
		last if (length($line) == 0 || ($line =~ /^_+$/));

		# remove that annoying trailing: (contents, props changed)			
		$path =~ s/\s*\(contents, props changed\)\s*$//;
		 
		# remove that annoying trailing: (props changed)			
		$path =~ s/\s*\(props changed\)\s*$//;

		# trim any leading/trailing whitespace
		$path = FreshPorts::Utilities::trim($path);
		 
#print "path='$path'\n";
		push @files, 'FILE', [ { Action => $action, Revision => $revision, Path => $path } ];
	}

	if (scalar(@files) == 0) {
		@files = GetFilesImported($message);
	}

	return @files;
}

sub GetFilesImported {
	my ($message) = shift;
	my (@files);
	my (@lines) = split("\n", $message);

	my $EndOfFiles = 'by this import';

	my %TrackDuplicates;

	# Modified Files
	my ($found) = 0;
	for (@lines) {
		my ($line) = $_;

		#
		# see also GetLog for use of Revision.
		#
		if ($line =~ /^  Release Tags:/i) { $found = 1; next; }
		next unless $found == 1;

		$line = FreshPorts::Utilities::trim($line);

		# immediately after the Release Tags line is a blank line
		next if ($line eq '');

		last if ($line =~ /by this import/i);

		my ($action, $path) = split(" ", $line);

		# we discard the $action obtained above as it is not needed
		$action = $FreshPorts::Constants::ADD;
		my $revision = '1.1.1.1';
		my $changes1 = '0';
		my $changes2 = '0';

		if (defined($TrackDuplicates{$path})) {
			FreshPorts::Utilities::ReportErrorEmailNoPrint('err', "Duplicate file name ('$path') found in commit message (" . GetMessage_Id($message) . ").\n\nIs this a corrupted commit or email?", 0)
		} else {
			$TrackDuplicates{$path} = 1;
		}

		push @files, 'FILE', [ { Action => $action, Revision => $revision, Changes => "$changes1 $changes2", Path => $path } ]; 
	}

	return @files;
}

sub GetOS_Id {
	my ($message) = @_;

	return 'FreeBSD';
}

sub GetOS_Branch {
	my ($message) = @_;
	my ($branch);
	
	my $Message_Subject = &GetMessage_Subject($message);

	if ($Message_Subject =~ m@\s+head/|\s+head$|\s+head:\s+@) {
		$branch = $FreshPorts::Constants::HEAD;
	}
	elsif ($Message_Subject =~ m@\s+stable/(\d+)@) {
		$branch = "RELENG_$1";
	}
	elsif ($Message_Subject =~ m@\s+branches/(RELENG[_\d]+)[/]*@) {
		$branch = "$1";
	}
	elsif ($Message_Subject =~ m@\s+vendor/@) {
		$branch = "VENDOR";
	}
	else {
		$branch = "UNKNOWN";
	}

	return $branch;
}

sub GetOS_RepoPrefix {
#
# Scan the message looking for a List Id.  Convert that to a repo prefix
# which will be prefixed to each filename in this commit.
#

	my ($message) = @_;

	my $myRepoPrefix = '';
	my $myListId     = FreshPorts::ProcessMail::myGetList_Id($message);

        my $ListProperties = FreshPorts::Branches::ListProperties($myListId);

        if (defined($ListProperties))
        {
    		 $myRepoPrefix = $ListProperties->{'repo'};
        }

	return $myRepoPrefix;
}

sub GetLog {
	my ($message)  = @_;
	my ($log)      = '';
	my ($log_done) = 0;

	#
	# List of phrases marking the end of the log
	# see also GetFiles for use of Revision
	#
	my (@log_endings) = ( 'Modified:', 'Added:', 'Deleted:' );

	my (@lines) = split("\n", $message);

	my ($log_found) = 0;
	for (@lines) {
		my ($line) = $_;

		# remove trailing spaces.
#		$line =~ s/ +$//;
#		$line .= "\n";

		if ($line =~ /^Log:/i) { $log_found = 1; next; }
		next unless ($log_found == 1);

		# XXX: Let's stick with this simple QP parser 
#		$line =~ s/=([0-9A-Fa-f][0-9A-Fa-f])/chr hex $1/ge;
		$line =~ s/=[\n\r]+$//;
#		print $line;

		# Check to see if we've gone too far
		for (@log_endings) {
			if ($line =~ /^$_/) { $log_done = 1; };
		}
		last if ($log_done == 1);

		# here we remove the two spaces at the start of the log which are added
		# by the email composing script
		if (length($line) >= 2) {
			$log .= substr($line,2) . "\n";
		}
	       	else {
			$log .= $line . "\n";
		}
	}

	# and we remove any trailing space in the log message
	$log =~ s/\s+$//;

	return $log;
}

sub GetUpdater_Handle {
	my ($message) = @_;
	my ($handle);

	my (@lines) = split("\n", $message);

	my ($newline_found) = 0;
	for (@lines) {
		next unless (/^Author:\s+(.*)/);
		$handle = $1;
		last;
	}

	return $handle;
}

sub GetDate {
	my ($message) = @_;
	my ($date, $year, $month, $day);

	my (@lines) = split("\n", $message);

	my ($newline_found) = 0; 
	for (@lines) {
		# e.g. Tue, 7 Oct 2008 20:57:55 +0000 (UTC)
		next unless (/^Date:\s+(.*)/);
		(undef, undef, undef, $day, $month, $year, undef) = strptime($1);
		$year += 1900;
		$month++;
		last;
	}

	$date = {	Year	=> $year,
				Month	=> int($month),
				Day		=> int($day) };

	return $date;
}
 
sub GetTime {
	my ($message) = @_;                     
	my ($time, $hour, $minute, $second, $timezone);
												 
	my (@lines) = split("\n", $message);
		
	my ($newline_found) = 0;
	for (@lines) {
		# e.g. Tue, 7 Oct 2008 20:57:55 +0000 (UTC)
		next unless (/^Date:\s+(.*)/);
		($second, $minute, $hour, undef, undef, undef, undef) = strptime($1);
		# extract zone part
		$timezone = $1 if (m/.*\(([A-Z0-9]+)\)/);
		last;
	}

	if (!defined($timezone)) {
		$timezone = '';
	}
										
	$time = {	Hour		=> int($hour),
				Minute		=> int($minute),
				Second		=> int($second),
				Timezone	=> $timezone };

	return $time;
}

sub GetMessage_Date {
	my ($message) = @_;
	my ($date, $year, $month, $day);
	my (%months) = ( 'Jan' => 1, 'Feb' => 2, 'Mar' => 3, 'Apr' => 4, 'May' => 5, 'Jun' => 6, 'Jul' => 7, 'Aug' => 8, 'Sep' => 9, 'Oct' => 10, 'Nov' => 11, 'Dec' => 12 ); 

	my (@lines) = split("\n", $message);

	for (@lines) {
		my ($line) = $_;

		if ($line =~ /^Date: /i) {
			($day, $month, $year) = (split(/\s+/, $line))[2..4];
			last;
		}
	}

	$date = {   Year    => $year,
				Month   => int($months{$month}),     
				Day     => int($day) };

	return $date;
}
										  
sub GetMessage_Time {
	my ($message) = @_;
	my ($time, $hour, $minute, $second, $timezone);

	my (@lines) = split("\n", $message);
												
	for (@lines) {
		my ($line) = $_;
										  
		if ($line =~ /^Date: /i) {
			($time, $timezone) = (split(/\s+/, $line))[5,7];
			($hour, $minute, $second) = split(/:/, $time);
			
			if (!defined($timezone)) {
				$timezone = '';
			}

			if ($timezone =~ m/\S/) {
				$timezone = substr($timezone, 1, 3);
			}
			last;
		}
	}

	if (!defined($timezone)) {
		$timezone = '';
	}

	$time = {	Hour		=> int($hour),
				Minute		=> int($minute),
				Second		=> int($second),
				Timezone	=> $timezone };

	return $time;
}

sub GetMessage_Id {
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

sub GetMessage_To {
	my ($message) = @_;
	my ($data, $to);

	my (@lines) = split("\n", $message);

	for (@lines) {
		my ($line) = $_;

		if ($line =~ /^To: /i) {
			$data = (split/: /, $line, 2)[1];
			last;
		}
	}

	my (@data) = split(/, /, $data);

	my (@to) = ();
	for (@data) {
		push @to, 'TO';
		push @to, [{ 'Email' => $_ } ];
	}

	return @to;
}

sub GetMessage_Subject {
#

	my ($message) = @_;
	my ($Subject);

	my %arg;
	my $email = Email::Simple->new($message, \%arg);
	my $SubjectHead = $email->header("Subject");

	return $SubjectHead;
}


1;
