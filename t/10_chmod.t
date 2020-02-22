#!/usr/bin/perl

# See https://github.com/redhotpenguin/perl-Archive-Zip/blob/master/t/README.md
# for a short documentation on the Archive::Zip test infrastructure.

use strict;

BEGIN { $^W = 1; }

use Test::More;

use Archive::Zip qw();

use lib 't';
use common;

# Test whether a member with read-only Unix permissions is
# extracted as read-only file.

sub get_perm {
    my $filename = shift;

    return (((stat($filename))[2]) & 07777);
}

sub test_perm {
    my $filename = shift;
    my $perm     = shift;

    # ignore errors here
    chmod($perm, $filename);

    return (get_perm($filename) == $perm);
}

sub test_if_chmod_is_working {
    my $test_file = testPath("test.file");

    open my $out, ">$test_file" or die;
    print {$out} "Foobar.";
    close($out);

    my $verdict =
        test_perm($test_file, 0444) &&
        test_perm($test_file, 0666) &&
        test_perm($test_file, 0444);

    unlink($test_file) or die;

    return $verdict;
}

if (!test_if_chmod_is_working()) {
    plan skip_all => "chmod() is not working on this machine.";
} else {
    plan tests => 4;
}

my $test_file = testPath("test.file");

my $zip = Archive::Zip->new();
isa_ok($zip, 'Archive::Zip');
azok($zip->read(dataPath("chmod.zip")));
azok($zip->memberNamed("test_dir/test_file")->extractToFileNamed($test_file));
is(get_perm($test_file), 0444, "File permission is OK.");
