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
use Archive::Zip qw( :CONSTANTS );

use Test::More tests => 12;
use lib 't';
use common;

my ($testFileVolume, $testFileDirs, $testFileName) = File::Spec->splitpath($0);

my $zip = Archive::Zip->new();
my $testDir = File::Spec->catpath($testFileVolume, $testFileDirs, '');

my $numberOfMembers = 0;
my @memberNames;

sub countMembers {
    unless ($_ eq '.') { push(@memberNames, $_); $numberOfMembers++; }
}
File::Find::find(\&countMembers, $testDir);
is($numberOfMembers > 1, 1, 'not enough members to test');

# an initial updateTree() should act like an addTree()
azok($zip->updateTree($testDir), 'initial updateTree failed');
is(scalar($zip->members()),
    $numberOfMembers, 'wrong number of members after create');

my $firstFile   = $memberNames[0];
my $firstMember = ($zip->members())[0];

is($firstFile, $firstMember->fileName(), 'member name wrong');

# add a file to the directory
$testFileName = File::Spec->catpath($testFileVolume, $testFileDirs, 'xxxxxx');
my $fh = IO::File->new($testFileName, 'w');
$fh->print('xxxx');
undef($fh);
is(-f $testFileName, 1, "creating $testFileName failed");

# Then update it. It should be added.
azok($zip->updateTree($testDir), 'updateTree failed');
is(
    scalar($zip->members()),
    $numberOfMembers + 1,
    'wrong number of members after update'
);

# Delete the file.
unlink($testFileName);
is(-f $testFileName, undef, "deleting $testFileName failed");

# updating without the mirror option should keep the members
azok($zip->updateTree($testDir), 'updateTree failed');
is(
    scalar($zip->members()),
    $numberOfMembers + 1,
    'wrong number of members after update'
);

# now try again with the mirror option; should delete the last file.
azok($zip->updateTree($testDir, undef, undef, 1), 'updateTree failed');
is(scalar($zip->members()),
    $numberOfMembers, 'wrong number of members after mirror');
