#!/usr/bin/perl

# See https://github.com/redhotpenguin/perl-Archive-Zip/blob/master/t/README.md
# for a short documentation on the Archive::Zip test infrastructure.

use strict;

BEGIN { $^W = 1; }

use Test::More tests => 32;

use Archive::Zip qw(:CONSTANTS);

use lib 't';
use common;

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
# mapped to a zero length stored member, regardless of the compression
# method used or the use of streaming.
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

# [<input-file>  => "<ref-file>", <comp-method>|undef, ]
my @TESTS = (
  # Implicit tests - check that COMPRESSION_STORED gets used when
  # no compression method has been set.
  [emptydef      => "emptystore", undef,               ],
  [emptydefstr   => "emptystore", undef,               ],
  [emptystore    => "emptystore", undef,               ],
  [emptystorestr => "emptystore", undef,               ],

  # Explicitly set desired compression
  [emptydef      => "emptystore", COMPRESSION_STORED,  ],
  [emptydefstr   => "emptystore", COMPRESSION_STORED,  ],
  [emptystore    => "emptystore", COMPRESSION_STORED,  ],
  [emptystorestr => "emptystore", COMPRESSION_STORED,  ],

  [emptydef      => "emptystore", COMPRESSION_DEFLATED,],
  [emptydefstr   => "emptystore", COMPRESSION_DEFLATED,],
  [emptystore    => "emptystore", COMPRESSION_DEFLATED,],
  [emptystorestr => "emptystore", COMPRESSION_DEFLATED,],

  # The following non-empty files should not be changed at all
  [def           => "def",        undef,               ],
  [defstr        => "defstr",     undef,               ],
  [store         => "store",      undef,               ],
  [storestr      => "storestr",   undef,               ],
);

for my $test (@TESTS)
{
    my ($infile, $reffile, $method) = @$test;
    $infile = dataPath($infile);
    $reffile = dataPath($reffile);
    my $outfile = OUTPUTZIP;

    passThrough($infile, $outfile, sub {
        my $member = shift;
        $member->desiredCompressionMethod($method) if defined($method);
        $member->setLastModFileDateTimeFromUnix($member->lastModTime());
    });
    azuztok($outfile, 'name' => "\"unzip -t\" ok after $infile to $outfile");

    my $outtext = readFile($outfile);
    my $reftext = readFile($reffile);
    ok($outtext eq $reftext, "$outfile eq $reffile");
}
