#!/usr/bin/perl

use strict;

BEGIN {
    $|  = 1;
    $^W = 1;
}

use Test::More tests => 32;
use lib 't';
use common;
use Archive::Zip qw( :CONSTANTS );


# RT #92205: CRC error when re-writing Zip created by LibreOffice

# Archive::Zip was blowing up when processing member
# 'Configurations2/accelerator/current.xml' from the LibreOffice file.
#
# 'current.xml' is a zero length file that has been compressed AND uses
# streaming. That means the uncompressed length is zero but the compressed
# length is greater than 0.
#
# The fix for issue #101092 added code that forced both the uncompressed &
# compressed lengths to be zero if either was zero. That caused this issue.


# This set of test checks that a zero length zip member will ALWAYS be
# mapped to a zero length Stored member, regardless of the compression
# method used or the use of streaming.
#
#
# Input files all contain a single zero length member.
# Streaming & Compression Method are set as follows.
#
# File                Streamed    Method
# ===============================================
# emptydef.zip        No          Deflate
# emptydefstr.zip     Yes         Deflate
# emptystore.zip      No          Store
# emptystorestr.zip   Yes         Store
#
# See t/data/mkzip.pl for the code used to create these zip files.


my @empty = map { dataPath($_) }
            qw( emptydef emptydefstr emptystore emptystorestr );

# Implicit tests - check that stored gets used when no compression method
# has been set.
for my $infile (@empty)
{
    my $expectedout = dataPath("emptystore.zip");
    my $outfile = OUTPUTZIP;

    passThrough($infile, $outfile, sub {
        my $member = shift ;
        $member->setLastModFileDateTimeFromUnix($member->lastModTime());
     });

    my $expected = readFile($expectedout);
    my $after = readFile($outfile);

    azuztok($outfile, 'name' => "\"unzip -t\" ok after $infile to $outfile");
    ok $expected eq $after, "$expectedout eq $outfile";
}



# Explicitly set desired compression
for my $method ( COMPRESSION_STORED, COMPRESSION_DEFLATED)
{
    for my $infile (@empty)
    {
        my $outfile = OUTPUTZIP;
        my $expectedout = dataPath("emptystore.zip");

        passThrough($infile, $outfile, sub {
            my $member = shift ;
            $member->desiredCompressionMethod( $method );
            $member->setLastModFileDateTimeFromUnix($member->lastModTime());
         });

        my $expected = readFile($expectedout);
        my $after = readFile($outfile);

        azuztok($outfile, 'name' => "[$method] \"unzip -t\" ok after $infile to $outfile");
        ok $after eq $expected, "[$method] $infile eq $outfile";
    }
}

# The following non-empty files should not be changed at all
my @nochange = map { dataPath($_) }
               qw( def defstr store storestr );

for my $infile (@nochange)
{
    my $outfile = OUTPUTZIP;

    passThrough($infile, $outfile, sub {
        my $member = shift ;
        $member->setLastModFileDateTimeFromUnix($member->lastModTime());
     });

    my $expected = readFile($infile);
    my $after = readFile($outfile);

    azuztok($outfile, 'name' => "\"unzip -t\" ok after $infile to $outfile");
    ok $expected eq $after, "$infile eq $outfile";
}
