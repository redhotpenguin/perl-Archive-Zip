#!/usr/bin/perl

# See https://github.com/redhotpenguin/perl-Archive-Zip/blob/master/t/README.md
# for a short documentation on the Archive::Zip test infrastructure.

use strict;

BEGIN { $^W = 1; }

use Test::More;

use Archive::Zip qw(:ERROR_CODES);

use lib 't';
use common;

# Test symbolic link extraction

my $ZIP_FILE = dataPath('symlink.zip');
my $SYM_LINK = testPath('some', 'dir', 'symlink');

# Symlink tests make sense only if a file system supports them.
my $symlinks_not_supported;
{
    my $link = testPath('trylink');
    $symlinks_not_supported = !eval { symlink('.', $link) };
    unlink($link);
}

if ($symlinks_not_supported) {
    plan(skip_all => 'Symlinks not supported.');
} else {
    plan(tests => 16);
}

my $zip = Archive::Zip->new();
isa_ok($zip, 'Archive::Zip');
azok($zip->read($ZIP_FILE), 'Archive read');
my $symlink = $zip->memberNamed('foo/bar/symlink');
isa_ok($symlink, 'Archive::Zip::Member', 'Member found');

# Test method extractToFileNamed
azis($symlink->extractToFileNamed($SYM_LINK), AZ_OK, 'Link extraction (1)');
azis($symlink->extractToFileNamed($SYM_LINK), AZ_IO_ERROR, 'Link extraction failure (1)');
ok(-l $SYM_LINK, 'Symlink (1)');
is(readlink($SYM_LINK), "target", 'Symlink target (1)');
ok(unlink($SYM_LINK), 'Symlink cleanup (1)');

# Test method extractToFileHandle.  Above test already created
# the required directories.
azis($symlink->extractToFileHandle($SYM_LINK), AZ_OK, 'Link extraction (2)');
azis($symlink->extractToFileHandle($SYM_LINK), AZ_IO_ERROR, 'Link extraction failure (2)');
ok(-l $SYM_LINK, 'Symlink (2)');
is(readlink($SYM_LINK), "target", 'Symlink target (2)');
ok(unlink($SYM_LINK), 'Symlink cleanup (2)');

# Test symlink creation during tree extraction
azis($zip->extractTree('', testPath()), AZ_OK, 'Tree extraction');
ok(-l testPath('foo', 'bar', 'symlink'), 'Symlink (3)');
is(readlink(testPath('foo', 'bar', 'symlink')), 'target', 'Symlink target (3)');
