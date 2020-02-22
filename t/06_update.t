#!/usr/bin/perl

# See https://github.com/redhotpenguin/perl-Archive-Zip/blob/master/t/README.md
# for a short documentation on the Archive::Zip test infrastructure.

use strict;

BEGIN { $^W = 1; }

use IO::File;
use File::Find;
use File::Spec;
use File::Spec::Unix;
use Test::More tests => 16;

use Archive::Zip qw();

use lib 't';
use common;

# Test Archive::Zip::updateTree

# copy small files from directory "t" to our test directory
{
    my $zip = Archive::Zip->new();
    isa_ok($zip, 'Archive::Zip');
    azok($zip->addTree('t', '', sub { my $s = -s; defined($s) && $s < 1000 }));
    azok($zip->extractTree('', testPath(PATH_ZIPFILE)));
}

# collect names of files and directories below test directory in
# Zip (internal) file name format
my @fileNames = ();
sub collectFiles {
    my $fnz;
    if (-f) {
        my (undef(), $dirs, $fn) = File::Spec->splitpath($File::Find::name);
        my (@dirs) = File::Spec->splitdir($dirs);
        $fnz = File::Spec::Unix->catfile(@dirs, $fn);
    }
    else {
        my (undef(), $dirs, undef()) = File::Spec->splitpath($File::Find::name, 1);
        my (@dirs) = File::Spec->splitdir($dirs);
        $fnz = File::Spec::Unix->catfile(@dirs) . "/";
    }
    push(@fileNames, $fnz);
}
File::Find::find(\&collectFiles, testPath());
@fileNames = sort(@fileNames);
ok(@fileNames > 10, 'not enough files to test');
ok(grep { m@/data/@ } @fileNames, 'missing "data" directory');

my ($zip, @memberNames);

# an initial updateTree() should act like an addTree()
$zip = Archive::Zip->new();
isa_ok($zip, 'Archive::Zip');
azok($zip->updateTree(testPath(), testPath(PATH_ZIPFILE)), 'initial updateTree failed');
@memberNames = sort map { $_->fileName() } $zip->members();
is_deeply(\@memberNames, \@fileNames, 'wrong members after create');

# add a file to the directory
my $fnz = testPath('data', 'xxxxxx', PATH_ZIPFILE);
my $fn  = testPath('data', 'xxxxxx');
my $fh  = IO::File->new($fn, 'w');
$fh->print('xxxx');
close($fh);
ok(-f $fn, "creating $fn failed");

# Then update it. It should be added.
azok($zip->updateTree(testPath(), testPath(PATH_ZIPFILE)), 'updateTree failed');
@memberNames = sort map { $_->fileName() } $zip->members();
is_deeply(\@memberNames, [sort(@fileNames, $fnz)], 'wrong members after update');

# Delete the file.
unlink($fn);
ok(! -f $fn, "deleting $fn failed");

# updating without the mirror option should keep the members
azok($zip->updateTree(testPath(), testPath(PATH_ZIPFILE)), 'updateTree failed');
@memberNames = sort map { $_->fileName() } $zip->members();
is_deeply(\@memberNames, [sort(@fileNames, $fnz)], 'wrong members after update');

# now try again with the mirror option; should delete the last file.
azok($zip->updateTree(testPath(), testPath(PATH_ZIPFILE), undef, 1), 'updateTree failed');
@memberNames = sort map { $_->fileName() } $zip->members();
is_deeply(\@memberNames, \@fileNames, 'wrong members after mirror update');
