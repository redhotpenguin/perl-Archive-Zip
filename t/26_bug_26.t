#!/usr/bin/perl

use strict;

BEGIN {
    $|  = 1;
    $^W = 1;
}

use Test::More tests => 1;
use lib 't';
use common;
use Archive::Zip qw( :CONSTANTS );


my $infile = "t/data/bzip.zip";
my $outfile = OUTPUTZIP;


my $zip = Archive::Zip->new();
$zip->read($infile);
$zip->writeToFileNamed($outfile);

my ($status, $reason) = testZip($outfile);
is $status, 0, "testZip ok after $infile to $outfile"
    or warn("ziptest said: $reason\n");

