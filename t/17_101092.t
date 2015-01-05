#!/use/bin/perl

use strict;

BEGIN {
    $|  = 1;
    $^W = 1;
}

use Test::More tests => 2;
use t::common;

# RT #101092: Creation of non-standard streamed zip file

# Test that reading a zip file that contains a streamed member, then writing
# it without modification will set the local header fields for crc, compressed 
# length & uncompressed length all to zero.

# streamed.zip can be created with the following one-liner:
#
# perl -MIO::Compress::Zip=zip -e 'zip \"abc" => "streamed.zip", Name => "fred", Stream => 1, Method =>8'

my $infile = "t/data/streamed.zip";
my $outfile = OUTPUTZIP;
passthrough($infile, $outfile); 

my $before = readFile($infile);
my $after = readFile($outfile);

my ($status, $reason) = testZip($outfile);
is $status, 0
    or warn("ziptest said: $reason\n");
ok $before eq $after;

