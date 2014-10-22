#!/usr/bin/perl

# These are regression tests for:
# http://rt.cpan.org/Public/Bug/Display.html?id=27463
# http://rt.cpan.org/Public/Bug/Display.html?id=76780
#
# It tests that one can add files to the archive whose filenames are "0".

use strict;

BEGIN {
    $|  = 1;
    $^W = 1;
}
use Test::More tests => 3;
use Archive::Zip;

use File::Path;
use File::Spec;

use t::common;

mkpath([File::Spec->catdir(TESTDIR, 'folder')]);

my $zero_file = File::Spec->catfile(TESTDIR, 'folder', "0");
open(O, ">$zero_file");
print O "File 0\n";
close(O);

my $one_file = File::Spec->catfile(TESTDIR, 'folder', '1');
open(O, ">$one_file");
print O "File 1\n";
close(O);

my $archive = Archive::Zip->new;

$archive->addTree(File::Spec->catfile(TESTDIR, 'folder'), 'folder',);

# TEST
ok(
    scalar(grep { $_ eq "folder/0" } $archive->memberNames()),
    "Checking that a file called '0' was added properly"
);

rmtree([File::Spec->catdir(TESTDIR, 'folder')]);

# Cannot create member called "0" with addString
{
    # Create member "0" with addString
    my $archive = Archive::Zip->new;
    my $string_member = $archive->addString(TESTSTRING => 0);
    $archive->writeToFileNamed(OUTPUTZIP);
}

{

    # Read member "0"
    my $archive = Archive::Zip->new;
    is($archive->read(OUTPUTZIP), Archive::Zip::AZ_OK);
    ok(scalar(grep { $_ eq "0" } $archive->memberNames()),
        "Checking that a file called '0' was added properly by addString");
}
unlink(OUTPUTZIP);
