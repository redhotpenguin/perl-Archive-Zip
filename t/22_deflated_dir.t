#!/usr/bin/perl

use strict;
use warnings;

use Archive::Zip qw( :ERROR_CODES );
use File::Spec;
use t::common;

use Test::More tests => 4;

my $zip = Archive::Zip->new();
isa_ok( $zip, 'Archive::Zip' );
is( $zip->read(File::Spec->catfile('t', 'data', 'jar.zip')), AZ_OK, 'Read file' );

my $ret = eval { $zip->writeToFileNamed(OUTPUTZIP) };

TODO: {
    local $TODO = 'files with deflated directories cannot be written out';
is($ret, AZ_OK, 'Wrote file');

my ($status, $zipout) = testZip();
# STDERR->print("status= $status, out=$zipout\n");
skip( "test zip doesn't work", 1 ) if $testZipDoesntWork;
is( $status, 0, "output zip isn't corrupted" );
} # TODO
