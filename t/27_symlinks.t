#!/usr/bin/perl

use strict;
use warnings;

use Archive::Zip qw( :ERROR_CODES );
use Test::More;
use File::Spec;
use File::Path;
use lib 't';
use common;

# Test symbolic link extraction

my $ZIP_FILE  = dataPath('symlink.zip');
my $TEST_DIR  = File::Spec->catfile(TESTDIR, 'dir');
my $TEST_FILE = File::Spec->catfile($TEST_DIR, 'symlink');

# Symlink tests make sense only if a file system supports them.
my $symlinks_not_supported;
{
    my $link = 'trylink';
    $symlinks_not_supported = !eval { symlink('.', $link) };
    unlink $link;
}

if ($symlinks_not_supported) {
    plan(skip_all => 'Symlinks not supported.');
} else {
    plan(tests => 16);
}

rmtree([TESTDIR], 0, 0);

my $zip = Archive::Zip->new();
isa_ok($zip, 'Archive::Zip');
azok($zip->read($ZIP_FILE), 'Archive read');
my $symlink = $zip->memberNamed('foo/bar/symlink');
isa_ok($symlink, 'Archive::Zip::Member', 'Member found');

# Test method extractToFileNamed
azis($symlink->extractToFileNamed($TEST_FILE), AZ_OK, 'Link extraction (1)');
azis($symlink->extractToFileNamed($TEST_FILE), AZ_IO_ERROR, 'Link extraction failure (1)');
ok(-l $TEST_FILE, 'Symlink (1)');
is(readlink($TEST_FILE), "target", 'Symlink target (1)');
ok(unlink($TEST_FILE), 'Symlink cleanup (1)');

# Test method extractToFileHandle.  Above test already
# created the required directories.
azis($symlink->extractToFileHandle($TEST_FILE), AZ_OK, 'Link extraction (2)');
azis($symlink->extractToFileHandle($TEST_FILE), AZ_IO_ERROR, 'Link extraction failure (2)');
ok(-l $TEST_FILE, 'Symlink (2)');
is(readlink($TEST_FILE), "target", 'Symlink target (2)');
ok(unlink($TEST_FILE), 'Symlink cleanup (2)');

# Test symlink creation during tree extraction
azis($zip->extractTree('', $TEST_DIR), AZ_OK, 'Tree extraction');
ok(-l File::Spec->catfile($TEST_DIR, 'foo', 'bar', 'symlink'), 'Symlink (3)');
is(readlink(File::Spec->catfile($TEST_DIR, 'foo', 'bar', 'symlink')), 'target',
   'Symlink target (3)');
