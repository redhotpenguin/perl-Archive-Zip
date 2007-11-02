#!/usr/bin/perl

# Test Archive::Zip updating

use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}
use File::Spec ();
use IO::File   ();
use File::Find ();
use Archive::Zip qw( :ERROR_CODES :CONSTANTS );

use Test::More tests => 12;
BEGIN {
    unshift @INC, "t/"; 
    require( File::Spec->catfile('t', 'common.pl') )
		or die "Can't load t/common.pl";
}

my ($testFileVolume, $testFileDirs, $testFileName) = File::Spec->splitpath($0);

my $zip = Archive::Zip->new();
my $testDir = File::Spec->catpath( $testFileVolume, $testFileDirs, '' );

my $numberOfMembers = 0;
my @memberNames;
sub countMembers { unless ($_ eq '.')
	{ push(@memberNames, $_); $numberOfMembers++; } };
File::Find::find( \&countMembers, $testDir );
is( $numberOfMembers > 1, 1, 'not enough members to test');

# an initial updateTree() should act like an addTree()
is( $zip->updateTree( $testDir ), AZ_OK, 'initial updateTree failed' );
is( scalar($zip->members()), $numberOfMembers, 'wrong number of members after create' );

my $firstFile = $memberNames[0];
my $firstMember = ($zip->members())[0];

is( $firstFile, $firstMember->fileName(), 'member name wrong');

# add a file to the directory
$testFileName = File::Spec->catpath( $testFileVolume, $testFileDirs, 'xxxxxx' );
my $fh = IO::File->new( $testFileName, 'w');
$fh->print('xxxx');
undef($fh);
is( -f $testFileName, 1, "creating $testFileName failed");

# Then update it. It should be added.
is( $zip->updateTree( $testDir ), AZ_OK, 'updateTree failed' );
is( scalar($zip->members()), $numberOfMembers + 1, 'wrong number of members after update' );

# Delete the file.
unlink($testFileName);
is( -f $testFileName, undef, "deleting $testFileName failed");

# updating without the mirror option should keep the members
is( $zip->updateTree( $testDir ), AZ_OK, 'updateTree failed' );
is( scalar($zip->members()), $numberOfMembers + 1, 'wrong number of members after update' );

# now try again with the mirror option; should delete the last file.
is( $zip->updateTree( $testDir, undef, undef, 1 ), AZ_OK, 'updateTree failed' );
is( scalar($zip->members()), $numberOfMembers, 'wrong number of members after mirror' );
