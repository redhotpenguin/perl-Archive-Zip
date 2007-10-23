#!/usr/bin/perl -w

# This is a regression test for:
# http://rt.cpan.org/Public/Bug/Display.html?id=27463
#
# It tests that one can add files to the archive whose filenames are "0".

use strict;

use Test::More tests => 1;
use Archive::Zip;

use File::Path;
use File::Spec;

use constant TESTDIR => ('testdir');
use constant TEST_FOLDER => (TESTDIR(), "folder");

mkpath([ File::Spec->catdir(TEST_FOLDER()) ]);

open O, ">", File::Spec->catfile(TEST_FOLDER(), "0");
print O "File 0\n";
close(O);

open O, ">", File::Spec->catfile(TEST_FOLDER(), "1");
print O "File 1\n";
close(O);

my $archive = Archive::Zip->new;

$archive->addTree(File::Spec->catfile(TEST_FOLDER()), "folder");

# TEST
ok(scalar(grep { $_ eq "folder/0" } $archive->memberNames()),
    "Checking that a file called '0' was added properly"
);

rmtree([ File::Spec->catdir(TEST_FOLDER()) ]);

