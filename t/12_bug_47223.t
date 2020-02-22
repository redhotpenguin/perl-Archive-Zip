#!/usr/bin/perl

# See https://github.com/redhotpenguin/perl-Archive-Zip/blob/master/t/README.md
# for a short documentation on the Archive::Zip test infrastructure.

use strict;

BEGIN { $^W = 1; }

use Test::More;

use Archive::Zip qw();

use lib 't';
use common;

# Somewhere between version 1.26 and 1.28 function
# Archive::Zip::_asLocalName under certain conditions would
# incorrectly prepended cwd to an absolute destination file name
# while extracting trees.  This test ensures that this does not
# happen.  In addition this test uses short file names and
# Windows file name syntax in the destination directory.  The
# latter of which not beeing what the documentation prescribes.

if ($^O eq 'MSWin32') {
    plan(tests => 3);
} else {
    plan(skip_all => 'Only required on Win32.');
}

my $dist = dataPath('winzip.zip');
my $path = testPath('test', PATH_ABS);
mkdir $path
    or die "Could not create temporary directory '$path': $!";
$path = Win32::GetShortPathName($path)
    or die "Could not get short path name of temporary directory '$path': $!";

my $zip = Archive::Zip->new();
isa_ok($zip, 'Archive::Zip');
azok($zip->read($dist));
azok(eval { $zip->extractTree('', "$path/"); });
