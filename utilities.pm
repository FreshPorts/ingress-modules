#
#
# $Id: utilities.pm,v 1.27 2012-08-15 11:49:10 dan Exp $
#
# Copyright (c) 2001-2006 DVL Software
#

package FreshPorts::Utilities;

require FreshPorts::config;
require Sys::Syslog;

require FreshPorts::email;
require Text::Wrap;

# =================================

sub ReadFile($) {

	my $file = shift;
	my $content;

	open F,$file;
	if (stat F) {
		$content = "";
		while(<F>){
			$content .= $_;
		}
	} else {
		FreshPorts::Utilities::ReportError('warning', "cannot open file $file", 1);
	}

	close F;

	return $content;
}

#
# this function is invoked from many places.
#
sub FetchFile($;$;$;$;) {
	#
	# fetch a file
	# into the given path
	# returns 1 if fetched.
	# zero otherwise.
	#
	my $DESTDIR  = shift;
	my $SRCDIR   = shift;
	my $FILE     = shift;
	my $REVISION = shift;

	return FetchFileURL($FreshPorts::Config::SVN_Repository, $DESTDIR, $SRCDIR, $FILE, $REVISION, "''");
}

#
# This function is invoked only from FetchFile
# 
sub FetchFileURL($;$;$;$;$;$) {
	#
	# fetch a file
	# into the given path
	# returns 1 if fetched.
	# zero otherwise.
	#
	my $URL			= shift;
	my $DESTDIR		= shift;
	my $SRCDIR		= shift;
	my $FILE		= shift;
	my $REVISION	= shift;
	my $SUFFIX      = shift;
	
	my $REPO        = 'ports';

print "before '$SRCDIR'\n";
	$SRCDIR =~ s!^/?ports/!!;
	
	# special case, that I couldn't handle in a regex
	if ($SRCDIR eq $FreshPorts::Config::ports_prefix)
	{
		$SRCDIR = "''";
	}
print "after '$SRCDIR'\n";

	if ($FILE eq '')
	{
		$FILE = "''";
	}

#	print "FetchFileURL '$URL' '$DESTDIR' '$SRCDIR' '$FILE' '$REVISION' '$SUFFIX'\n";

	my $result = 0;

	my $FetchAttempts = $FreshPorts::Config::Fetch_Retry_Limit;

	while ($FetchAttempts) {
		my $command = "sh $FreshPorts::Config::scriptpath/svn-up-file.sh  SVNDIR SVNITEM REVISION $DESTDIR $SRCDIR $FILE $REVISION $SUFFIX";
		print "about to fetch = '$command'\n";
		my $FetchResults = `$command`;
		my $code = $?;
		print "fetch result = $code\n";
		if (($code >> 8)) {
			#
			# This might be a nice place to retry a fetch, or send an email
			#
			print "that fetch failed.  What do to?\n";
			print "\n\n" . $FetchResults . "\n\n";

			# and we're outta here
			# fetch failed
			# sleep, then try again

			FreshPorts::Utilities::ReportError('warning', "sleeping after fetch failed for ($DESTDIR $SRCDIR $FILE)");
			print "fetch failed, sleeping...\n";
			sleep $FreshPorts::Config::Fetch_Sleep_Time;
			$FetchAttempts--;

		} else {
			# fetch worked
			print "That fetch worked: '$FetchResults'\n";
			last;
		}
    }

	#
	# if we succeeded in our fetch..
	if ($FetchAttempts) {
		$result = 1;
	}

	return $result;
}

sub svnUpFile($;$;$) {
	#
	# fetch a file
	# into the given path
	# returns 1 if fetched.
	# zero otherwise.
	#
	my $SVNDIR   = shift;
	my $SVNITEM  = shift;
	my $REVISION = shift;
	
	$SVNITEM =~ s!^/?ports/!!;
	
	# special case, that I couldn't handle in a regex
	if ($SVNITEM eq $FreshPorts::Config::ports_prefix)
	{
		$SVNITEM = "''";
	}
print "after '$SVNITEM'\n";

	if ($SVNITEM eq '')
	{
		$SVNITEM = "''";
	}

#	print "svnUpFile '$SVNDIR' '$SVNITEM' '$REVISION'\n";

	my $result = 0;

	my $numAttempts = $FreshPorts::Config::Fetch_Retry_Limit;

	while ($numAttempts) {
		my $command = "sh $FreshPorts::Config::scriptpath/svn-up-file.sh $SVNDIR $SVNITEM $REVISION";
		print "about to svn up = '$command'\n";
		my $svnUpResults = `$command`;
		my $code = $?;
		print "svn up result = $code\n";
		if (($code >> 8)) {
			#
			# This might be a nice place to retry a fetch, or send an email
			#
			print "that svn up failed.  What do to?\n";
			print "\n\n" . $svnUpResults . "\n\n";

			# and we're outta here
			# fetch failed
			# sleep, then try again

			FreshPorts::Utilities::ReportError('warning', 'sleeping for ' . ($FreshPorts::Config::Fetch_Retry_Limit - $numAttempts + 1) * $FreshPorts::Config::Fetch_Sleep_Time . " seconds after svn up failed for ($SVNDIR $SVNITEM $REVISION)");
			print "fetch failed, sleeping...\n";
			# this waits less time each wait... should be longer each wait I think
			print "\$FreshPorts::Config::Fetch_Retry_Limit='$FreshPorts::Config::Fetch_Retry_Limit'\n";
			print "\$numAttempts='$numAttempts'\n";
			print "\$FreshPorts::Config::Fetch_Sleep_Time='$FreshPorts::Config::Fetch_Sleep_Time'\n";
			sleep (($FreshPorts::Config::Fetch_Retry_Limit - $numAttempts + 1) * $FreshPorts::Config::Fetch_Sleep_Time);
			$numAttempts--;

		} else {
			# fetch worked
			print "That fetch worked: '$svnUpResults'\n";
			last;
		}
    }

	#
	# if we succeeded in our fetch..
	if ($numAttempts) {
		$result = 1;
	}

	return $result;
}

#
# make sure we init only once...
#
$FreshPorts::Utilities::syslog_init = 0;

sub InitSyslog() {
	if (!$FreshPorts::Utilities::syslog_init) {
		Sys::Syslog::setlogsock('unix');
		Sys::Syslog::openlog('FreshPorts', 'cons, pid', 'local3');
		$FreshPorts::Utilities::syslog_init = 1;
	}
}


sub Report($;$) {
	my $level	= shift;
	my $message	= shift;

	_ReportErrorHelper($level, $message, 0, 0, 0);
}

sub ReportError($;$;$) {
	my $level	= shift;
	my $message	= shift;
	my $die		= shift;

	my $email   = $die;

	_ReportErrorHelper($level, $message, $email, $die, 1);
}

sub ReportErrorEmail($;$;$;$) {
	my $level	= shift;
	my $message	= shift;
	my $email   = shift;
	my $die		= shift;

	_ReportErrorHelper($level, $message, $email, $die, 1);
}

sub ReportErrorEmailNoPrint($;$;$;$) {
	my $level	= shift;
	my $message	= shift;
	my $email   = shift;
	my $die		= shift;

	_ReportErrorHelper($level, $message, $email, $die, 0);
}

sub _ReportErrorHelper($;$;$;$;$) {
	my $level	= shift;
	my $message	= shift;
	my $email	= shift;
	my $die		= shift;
	my $print	= shift;

	my $suffix = $FreshPorts::Config::scriptpath;

	Sys::Syslog::syslog($level, $message . " ($suffix)");
	if ($print) {
		print $message . "\n";
	}

	if ($email) {
		SendEmailNotice($FreshPorts::Config::SystemOwnerEmail, $message);
	}

	if ($die) {
		die $message . "\n";
	}
}

sub SendEmailNotice($;$) {
	my $To	 = shift;
	my $Body = shift;

	my $From         = 'FreshPorts Daemon <FreshPorts@FreshPorts.org>';
	my $CC           = '';
	my $Subject      = 'FreshPorts error on ' . `hostname`;

	# chomp gets right of vertical whitepace
	chomp($Subject);

	my %ExtraHeaders = (
		'Auto-Submitted'     => 'auto-generated',
		'Precedence'         => 'bulk',
		'X-FreshPorts-Error' => 'oops',
	);

	$Text::Wrap::columns = 72;

	$Body = "This message was generated by the FreshPorts Daemon.

The database is $FreshPorts::Config::dbname
at $FreshPorts::Config::FreshPortsURL

" . Text::Wrap::wrap('', '', $Body) . "

--
hugs+kisses
FreshPorts Daemon
";

	FreshPorts::email::SendMail($From, $To, $CC, $Subject, $Body, \%ExtraHeaders);
}

sub trim {
	my $s = shift;

	chomp($s);      # get rid of \n
	$s =~ s/^\s+//; # remove leading spaces
	$s =~ s/\s+$//; # remove trailing spaces

	return $s;
}

sub trim_multiple_to_single {
	my $s = shift;
	
	$s =~ s/\s+/ /g; # Convert multiple blank spaces to single spaces

	return $s;
}

sub TmpFileName($) {
	my $Tag = shift;

	($sec, $min, $hour, $mday, $mon, $year, $wday, $yday, $isdst) = localtime(time);

	$RealMonth = $mon  + 1;
	$RealYear  = $year + 1900;

	my $TmpFileName = '/tmp/FreshPorts.';
	if ($Tag ne '') {
		$TmpFileName .= "$Tag.";
	}
	$TmpFileName .= "$RealYear.$RealMonth.$mday.$hour.$min.$sec.$$";

	return $TmpFileName;
}


sub NULLIfEmpty {
	my $dbh   = shift;
	my $value = shift;

	my $result = undef;

	if (!defined($value) || $value eq '') {
		$result = 'NULL';
	} else {
		$result = $dbh->quote($value);
	}

	return $result;
}

sub CommitCountPeriod {
    my $dbh      = shift;
    my $interval = shift;
    
    my $count    = 0; #default to nothing...

	my $sth;
	my $sql;
	my @row;

	$sql = 'SELECT count(*) AS count FROM commit_log WHERE date_added > NOW() - INTERVAL ' . $dbh->quote($interval);

	$sth = $dbh->prepare($sql);
	if (!$sth->execute) {
		FreshPorts::Utilities::ReportError('warning', "Could not execute SQL $sql", 1);
	}

	$row = $sth->fetchrow_hashref();
	$sth->finish();

	# no sense setting values if we didn't get anything...
	if ($row) {
		$count = $row->{count};
	}

	return $count;
}

FreshPorts::Utilities::InitSyslog();

1;
