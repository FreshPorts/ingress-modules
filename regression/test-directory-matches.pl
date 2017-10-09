#!/usr/local/bin/perl -w

use strict;

my %Tests = (
	'ports/security/logcheck/Makefile'                   => 'ports/security/logcheck',
	'ports/www/privoxy+ipv6/files/patch-src::addrlist.c' => 'ports/www/privoxy+ipv6',
	'ports/security/portsentry/Makefile'                 => 'ports/Makefile',
	'ports/net/Makefile'                                 => 'ports/net/6to4',
	'ABC'                                                => 'ports/net/6to4',
);

while (my ($filename, $directory) = each %Tests) {
	print "\$filename = '$filename'\n\$directory= '$directory'\n";

	if ($filename =~ m|^/?\Q$directory\E/|) {
		print "   yes, that occurs under that directory\n";
	}

	print "\n";
}
