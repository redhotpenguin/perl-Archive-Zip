#!/usr/bin/perl

use strict;

BEGIN {
    $|  = 1;
    $^W = 1;
}

use Test::More tests => 6;
use File::Spec;
use lib 't';
use common;

use Archive::Zip;

my $expected_fn  = dataPath("expected.jpg");
my $expected_zip = "t/data/expected.jpg";
my $got_fn       = File::Spec->catfile(TESTDIR, "got.jpg");
my $archive_fn   = File::Spec->catfile(TESTDIR, "out.zip");

my ($before, $after);

sub run_tests {
    my $id     = shift;
    my $msg_it = sub {
        my $msg_raw = shift;
        return "$id - $msg_raw";
    };

    # Read the contents of the good file into the variable.
    $before = readFile($expected_fn);

    # Zip the file.
  SCOPE: {
        my $zip = Archive::Zip->new();
        $zip->addFile($expected_fn, $expected_zip);
        $zip->extractMember($expected_zip, $got_fn);
        $after = readFile($got_fn);

        unlink $got_fn;

        azbinis($after, $before,
                $msg_it->("Content of file after extraction"));

        azok($zip->writeToFileNamed($archive_fn),
             $msg_it->('Zip was written fine'));
    }

    # Read back the file from the archive.
  SCOPE: {
        my $zip2;
        $zip2 = Archive::Zip->new($archive_fn);

        $zip2->extractMember($expected_zip, $got_fn);

        $after = readFile($got_fn);

        unlink $got_fn;
        unlink $archive_fn;

        azbinis($after, $before,
                $msg_it->('Read back the file from the archive'));
    }
}

# Run the tests once with $\ undef.
run_tests("Normal");

# Run them once while setting $\.
SCOPE: {
    local $\ = "\n";
    run_tests(q{$\ is \n});
}
