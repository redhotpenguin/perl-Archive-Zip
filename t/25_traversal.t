#!/usr/bin/perl

# See https://github.com/redhotpenguin/perl-Archive-Zip/blob/master/t/README.md
# for a short documentation on the Archive::Zip test infrastructure.

use strict;

BEGIN { $^W = 1; }

use File::Spec;
use Test::More tests => 41;

use Archive::Zip qw(:ERROR_CODES);

use lib 't';
use common;

# These tests check for CVE-2018-10860 vulnerabilities.
# If an archive contains a symlink and then a file that traverses that symlink,
# extracting the archive tree could write into an abitrary file selected by
# the symlink value.
# Another issue is if an archive contains a file whose path component refers
# to a parent directory. Then extracting that file could write into a file
# out of current working directory subtree.
# These tests check extracting of these files is refused and that they are
# indeed not created.

my ($existed, $ret, $zip, $allowed_file, $forbidden_file);

# Change working directory to a temporary directory because some tested
# functions operate there and we need prepared symlinks there.
ok(chdir testPath(), "Working directory changed");

# Symlink tests make sense only if a file system supports them.
my $symlinks_not_supported;
{
    my $link = testPath('trylink');
    $symlinks_not_supported = !eval { symlink('.', $link) };
    unlink($link);
}

# Case 1:
#   link-dir -> /tmp
#   link-dir/gotcha-linkdir
# should not write into /tmp/gotcha-linkdir file.
SKIP: {
    skip 'Symbolic links are not supported', 12 if $symlinks_not_supported;

    # Extracting an archive tree must fail
    $zip = Archive::Zip->new();
    isa_ok($zip, 'Archive::Zip');
    azok($zip->read(dataPath('link-dir.zip', PATH_ABS)), 'Archive read');
    $existed = -e File::Spec->catfile('', 'tmp', 'gotcha-linkdir');
    $ret = eval { $zip->extractTree() };
    azis($ret, AZ_ERROR,
         qr/Could not extract .* safely: .* is an existing symbolic link/,
         'Tree extraction aborted');
    SKIP: {
        skip 'A canary file existed before the test', 1 if $existed;
        ok(! -e File::Spec->catfile('link-dir', 'gotcha-linkdir'),
           'A file was not created in a symlinked directory');
    }
    ok(unlink(File::Spec->catfile('link-dir')), 'link-dir removed');

    # The same applies to extracting an archive member without an explicit
    # local file name. It must abort.
    my $link = 'link-dir';
    ok(symlink('.', $link), 'A symlink to a directory created');
    $forbidden_file = File::Spec->catfile($link, 'gotcha-linkdir');
    $existed = -e $forbidden_file;
    $ret = eval { $zip->extractMember('link-dir/gotcha-linkdir') };
    azis($ret, AZ_ERROR,
         qr/Could not extract .* safely: .* is an existing symbolic link/,
         'Member extraction without a local name aborted');
    SKIP: {
        skip 'A canary file existed before the test', 1 if $existed;
        ok(! -e $forbidden_file,
           'A file was not created in a symlinked directory');
    }

    # But allow extracting an archive member into a supplied file name
    $allowed_file = File::Spec->catfile($link, 'file');
    $ret = eval { $zip->extractMember('link-dir/gotcha-linkdir', $allowed_file) };
    azok($ret, 'Member extraction passed');
    ok(-e $allowed_file, 'File created');
    ok(unlink($allowed_file), 'File removed');
    ok(unlink($link), 'A symlink to a directory removed');
}

# Case 2:
#   unexisting/../../../../../tmp/gotcha-dotdot-unexistingpath
# should not write into ../../../../tmp/gotcha-dotdot-unexistingpath,
# that is, /tmp/gotcha-dotdot-unexistingpath file if CWD is not deeper
# than 4 directories.
$zip = Archive::Zip->new();
isa_ok($zip, 'Archive::Zip');
azok($zip->read(dataPath('dotdot-from-unexistant-path.zip', PATH_ABS)), 'Archive read');
$forbidden_file = File::Spec->catfile('..', '..', '..', '..', 'tmp', 'gotcha-dotdot-unexistingpath');
SKIP: {
    skip "No /tmp on Windows", 2 if $^O eq 'MSWin32';

    $existed = -e $forbidden_file;
    $ret = eval { $zip->extractTree() };
    azis($ret, AZ_ERROR,
         qr/Could not extract .* safely: a parent directory is used/,
         'Tree extraction aborted');
    SKIP: {
        skip 'A canary file existed before the test', 1 if $existed;
        ok(! -e $forbidden_file, 'A file was not created in a parent directory');
    }
}

# The same applies to extracting an archive member without an explicit local
# file name. It must abort.
$existed = -e $forbidden_file;
$ret = eval { $zip->extractMember('unexisting/../../../../../tmp/gotcha-dotdot-unexistingpath') };
azis($ret, AZ_ERROR,
     qr/Could not extract .* safely: a parent directory is used/,
     'Member extraction without a local name aborted');
SKIP: {
    skip 'A canary file existed before the test', 1 if $existed;
    ok(! -e $forbidden_file, 'A file was not created in a parent directory');
}

# But allow extracting an archive member into a supplied file name
ok(mkdir('directory'), 'Directory created');
$allowed_file = File::Spec->catfile('directory', '..', 'file');
$ret = eval { $zip->extractMember('unexisting/../../../../../tmp/gotcha-dotdot-unexistingpath', $allowed_file) };
azok($ret, 'Member extraction passed');
ok(-e $allowed_file, 'File created');
ok(unlink($allowed_file), 'File removed');

# Case 3:
#   link-file -> /tmp/gotcha-samename
#   link-file
# should not write into /tmp/gotcha-samename. It must abort. (Or replace
# the symlink in more relaxed mode in the future.)
SKIP: {
    skip 'Symbolic links are not supported', 18 if $symlinks_not_supported;

    # Extracting an archive tree must fail
    $zip = Archive::Zip->new();
    isa_ok($zip, 'Archive::Zip');
    azok($zip->read(dataPath('link-samename.zip', PATH_ABS)), 'Archive read');
    $existed = -e File::Spec->catfile('', 'tmp', 'gotcha-samename');
    $ret = eval { $zip->extractTree() };
    azis($ret, AZ_ERROR,
         qr/Could not extract .* safely: .* is an existing symbolic link/,
         'Tree extraction aborted');
    SKIP: {
        skip 'A canary file existed before the test', 1 if $existed;
        ok(! -e File::Spec->catfile('', 'tmp', 'gotcha-samename'),
           'A file was not created through a symlinked file');
    }
    ok(unlink(File::Spec->catfile('link-file')), 'link-file removed');

    # The same applies to extracting an archive member using extractMember()
    # without an explicit local file name. It must abort.
    my $link = 'link-file';
    my $target = 'target';
    ok(symlink($target, $link), 'A symlink to a file created');
    $forbidden_file = File::Spec->catfile($target);
    $existed = -e $forbidden_file;
    # Select a member by order due to same file names.
    my $member = ${[$zip->members]}[1];
    ok($member, 'A member to extract selected');
    $ret = eval { $zip->extractMember($member) };
    azis($ret, AZ_ERROR,
         qr/Could not extract .* safely: .* is an existing symbolic link/,
         'Member extraction using extractMember() without a local name aborted');
    SKIP: {
        skip 'A canary file existed before the test', 1 if $existed;
        ok(! -e $forbidden_file,
           'A symlinked target file was not created');
    }

    # But allow extracting an archive member using extractMember() into
    # a supplied file name.
    $allowed_file = $target;
    $ret = eval { $zip->extractMember($member, $allowed_file) };
    azok($ret, 'Member extraction using extractMember() passed');
    ok(-e $allowed_file, 'File created');
    ok(unlink($allowed_file), 'File removed');

    # The same applies to extracting an archive member using
    # extractMemberWithoutPaths() without an explicit local file name.
    # It must abort.
    $existed = -e $forbidden_file;
    # Select a member by order due to same file names.
    $ret = eval { $zip->extractMemberWithoutPaths($member) };
    azis($ret, AZ_ERROR,
         qr/Could not extract .* safely: .* is an existing symbolic link/,
         'Member extraction using extractMemberWithoutPaths() without a local name aborted');
    SKIP: {
        skip 'A canary file existed before the test', 1 if $existed;
        ok(! -e $forbidden_file,
           'A symlinked target file was not created');
    }

    # But allow extracting an archive member using extractMemberWithoutPaths()
    # into a supplied file name.
    $allowed_file = $target;
    $ret = eval { $zip->extractMemberWithoutPaths($member, $allowed_file) };
    azok($ret, 'Member extraction using extractMemberWithoutPaths() passed');
    ok(-e $allowed_file, 'File created');
    ok(unlink($allowed_file), 'File removed');
    ok(unlink($link), 'A symlink to a file removed');
}
