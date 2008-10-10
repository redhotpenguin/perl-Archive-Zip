#!/usr/bin/perl

use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}
use Test::More;
use File::Spec;
use File::Path;
use Archive::Zip;

sub get_perm
{
    my $filename = shift;

    return (((stat($filename))[2]) & 07777);
}

sub test_if_chmod_is_working
{
    my $test_dir = File::Spec->catdir(
        File::Spec->curdir(), "testdir", "chtest"
    );

    my $test_file = File::Spec->catfile($test_dir, "test.file");

    mkdir($test_dir, 0755);

    open my $out, ">", $test_file;
    print {$out} "Foobar.";
    close($out);

    my $test_perm = sub {
        my $perm = shift;

        chmod ($perm, $test_file);

        return (get_perm($test_file) == $perm);
    };

    my $verdict = $test_perm->(0444) && $test_perm->(0666);

    # Clean up
    rmtree($test_dir);

    return $verdict;
}

if (!test_if_chmod_is_working())
{
    plan skip_all => "chmod() is not working on this machine.";
}
else
{
    plan tests => 1;
}

my $zip = Archive::Zip->new();

$zip->read(File::Spec->catfile(File::Spec->curdir(), "t", "data", "chmod.zip"));

my $test_dir = 
    File::Spec->catdir(
        File::Spec->curdir(), "testdir", "chtest"
    );

mkdir($test_dir, 0777);

my $test_file = File::Spec->catfile($test_dir, "test_file");

$zip->memberNamed("test_dir/test_file")->extractToFileNamed($test_file);

# TEST
is (get_perm($test_file), 
    0444,
    "File permission is OK."
);

# Clean up.
rmtree($test_dir);

