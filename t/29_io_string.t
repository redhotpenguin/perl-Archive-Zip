#!/usr/bin/perl

# See https://github.com/redhotpenguin/perl-Archive-Zip/blob/master/t/README.md
# for a short documentation on the Archive::Zip test infrastructure.

use strict;

BEGIN { $^W = 1; }

use Test::More;

use Archive::Zip qw(:ERROR_CODES :CONSTANTS);

use lib 't';
use common;

# Test symbolic link extraction

if (require IO::String) {
    plan(tests => 6);
} else {
    plan(skip_all => 'IO::String not installed.');
}

# Test writing to an IO::String object.
my $zipFileName = 'fake_file.zip';
my %tree = ('a.txt' => "a\n",
'dir/b.txt' => "b\n");

my $zipContents = '';
{
    my $SH          = IO::String->new($zipContents);

    my $zip = Archive::Zip->new();
    my $member;
    for my $file (sort keys %tree) {
        $member = $zip->addString($tree{$file}, $file);
        $member->desiredCompressionMethod(COMPRESSION_DEFLATED);
    }
    my $status = $zip->writeToFileHandle($SH);
    is $status, AZ_OK, "Wrote files to zip in string OK";
}

# Test reading from an IO::String object.
{
    # Demonstrates working from memory instead of a file.
    my $zip = Archive::Zip->new();
    my $fh = IO::String->new($zipContents);
    my $readStatus = $zip->readFromFileHandle({fileHandle => $fh, filename => $zipFileName});
    is $readStatus, AZ_OK, "Read zip from string to zip OK";
    for my $file (sort keys %tree) {
        my $member = $zip->memberNamed($file);
        my ($contents, $extractStatus) = $member->contents();
        is $extractStatus, AZ_OK, "Extracted '$file' from string" or next;
        is $contents, $tree{$file}, "Round-trip worked";
    }
}

done_testing();
