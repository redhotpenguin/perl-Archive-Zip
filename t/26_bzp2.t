#!/usr/bin/perl

# This test uses an archive, bzip.zip, that contains a member that uses bzip2 compression.
# The test is checking that the bzip2 member will pass-through to a new zip file without 
# causing corruption. 
# Before this fix  when you ran "unzip -t" on the newly created archive file it would report 
# that the fip zipe was corrupted.
#
# See https://github.com/redhotpenguin/perl-Archive-Zip/issues/26 for more details.

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

