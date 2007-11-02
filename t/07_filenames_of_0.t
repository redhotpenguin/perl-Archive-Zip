#!/usr/bin/perl

# This is a regression test for:
# http://rt.cpan.org/Public/Bug/Display.html?id=27463
#
# It tests that one can add files to the archive whose filenames are "0".

use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}

use Test::More tests => 1;
use Archive::Zip;

use File::Path;
use File::Spec;

mkpath([ File::Spec->catdir('testdir', 'folder') ]);

my $zero_file = File::Spec->catfile('testdir', 'folder', "0");
open( O, ">$zero_file" );
print O "File 0\n";
close(O);

my $one_file = File::Spec->catfile('testdir', 'folder', '1');
open( O, ">$one_file" );
print O "File 1\n";
close(O);

my $archive = Archive::Zip->new;

$archive->addTree(
	File::Spec->catfile('testdir', 'folder'),
	'folder',
);

# TEST
ok(scalar(grep { $_ eq "folder/0" } $archive->memberNames()),
    "Checking that a file called '0' was added properly"
);

rmtree([ File::Spec->catdir('testdir', 'folder') ]);
