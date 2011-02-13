#!perl

# Test the bug-fix for the following bug:
# Buggy behaviour:
#     Adding file or directory by absolute path results in leading separator
#     being stored in member name.
# Expected behaviour:
#     Discard leading separator
# Bug report: http://tech.groups.yahoo.com/group/perl-beginner/message/27085

use strict;

BEGIN {
    $^W = 1;
}

use Test::More tests => 1;
use Archive::Zip;

use Cwd        ();
use File::Spec ();

my $file_relative_path = File::Spec->catfile( 'testdir', 'file.txt' );
my $file_absolute_path = File::Spec->catfile(
    Cwd::getcwd(),
    $file_relative_path
);

my $az = Archive::Zip->new();
$az->addFile($file_absolute_path);

if ( $^O eq 'MSWin32' ) {

    # remove volume from absolute file path
    my ( undef, $directory_path, $current_directory ) = File::Spec->splitpath(
        Cwd::getcwd(),
        $file_relative_path
    );
    $file_absolute_path = File::Spec->catfile(
        $directory_path,
        $current_directory,
        $file_relative_path
    );

    $file_absolute_path =~ s{\\}{/}g;  # convert to Unix separators
}

# expect path without leading separator
( my $expected_member_name = $file_absolute_path ) =~ s{^/}{};
my ($member_name) = $az->memberNames();
is( $member_name, $expected_member_name, 'no leading separator' );
