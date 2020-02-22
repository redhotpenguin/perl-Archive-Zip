#!/usr/bin/perl

# See https://github.com/redhotpenguin/perl-Archive-Zip/blob/master/t/README.md
# for a short documentation on the Archive::Zip test infrastructure.

use strict;

BEGIN { $^W = 1; }

use Test::More tests => 2;

use Archive::Zip qw();

use lib 't';
use common;

# RT #101092: Creation of non-standard streamed zip file

# Test that reading a zip file that contains a streamed member, then writing
# it without modification will set the local header fields for crc, compressed
# length & uncompressed length all to zero.

# streamed.zip can be created with the following one-liner:
#
# perl -MIO::Compress::Zip=zip -e 'zip \"abc" => "streamed.zip", Name => "fred", Stream => 1, Method =>8'

my $infile = dataPath("streamed.zip");
my $outfile = OUTPUTZIP;
passThrough($infile, $outfile);
azuztok();

my $before = readFile($infile);
my $after = readFile($outfile);
ok($before eq $after);
