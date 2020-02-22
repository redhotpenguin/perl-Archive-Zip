#!/usr/bin/perl

# See https://github.com/redhotpenguin/perl-Archive-Zip/blob/master/t/README.md
# for a short documentation on the Archive::Zip test infrastructure.

use strict;

BEGIN { $^W = 1; }

use Test::More tests => 16;

use Archive::Zip qw();

use lib 't';
use common;

# Ensure archive reading and writing is independent of $/.

my $expected_fn  = dataPath("expected.jpg");
my $expected_zfn = dataPath("expected.jpg", PATH_ZIPFILE);
my $got_fn       = testPath("got.jpg");
my $archive_fn   = testPath("out.zip");

# Read the contents of the good file into the variable.
my $expected_txt = readFile($expected_fn);

sub run_tests {
    my $name = shift;

    # Zip the file.
    {
        my $zip = Archive::Zip->new();
        $zip->addFile($expected_fn, $expected_zfn);
        $zip->extractMember($expected_zfn, $got_fn);

        azbinis(readFile($got_fn), $expected_txt,
                "$name - Content of file after extraction");

        azwok($zip, 'file' => $archive_fn,
                    'name' => $name);
    }

    # Read back the file from the archive.
    {
        my $zip = Archive::Zip->new($archive_fn);
        $zip->extractMember($expected_zfn, $got_fn);

        azbinis(readFile($got_fn), $expected_txt,
                "$name - Read back the file from the archive");
    }
}

# Run the tests once with $\ undef.
{
    run_tests(q{$\ is unset});
}

# Run them once while setting $\.
{
    local $\ = "\n";
    run_tests(q{$\ is \n});
}
