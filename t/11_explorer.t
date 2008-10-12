#!/use/bin/perl

# Check Windows Explorer compatible directories

use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}

use Test::More tests => 4;
use Archive::Zip qw( :ERROR_CODES :CONSTANTS );

my $zip = Archive::Zip->new;
isa_ok( $zip, 'Archive::Zip' );
my $member = $zip->addDirectory('foo/');
ok(defined($member), 'Created a member');
is($member->fileName, 'foo/', '->fileName ok');
ok(
	$member->externalFileAttributes & 16,
	'Directory has directory bit set as expected by Windows Explorer',
);
