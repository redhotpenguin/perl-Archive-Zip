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

use Test::More tests => 8;
use lib 't';
use common;
use Archive::Zip qw( :CONSTANTS );


my $infile = dataPath("bzip.zip");
my $outfile = OUTPUTZIP;


my $zip = Archive::Zip->new();
isa_ok($zip, 'Archive::Zip');
azok($zip->read($infile));
azwok($zip);
