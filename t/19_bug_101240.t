#!/usr/bin/perl

# See https://github.com/redhotpenguin/perl-Archive-Zip/blob/master/t/README.md
# for a short documentation on the Archive::Zip test infrastructure.

use strict;

BEGIN { $^W = 1; }

use Test::More tests => 7;

use Archive::Zip qw(:CONSTANTS);

use lib 't';
use common;

#101240: Possible issue with zero length files on Win32 when UNICODE is enabled

my $input_file = testPath("empty.zip");

# Create a zip file that contains a member where compressed size is 0
{
    my $zip = Archive::Zip->new();
    my $string_member = $zip->addString( '', 'fred' );
    $string_member->desiredCompressionMethod(COMPRESSION_STORED);
    azok($zip->writeToFileNamed($input_file));
}

for my $unicode (0, 1)
{
    local $Archive::Zip::UNICODE = $unicode;

    my $zip = Archive::Zip->new();
    azok($zip->read($input_file));

    my $test_file = testPath("test_file$unicode");
    $zip->memberNamed("fred")->extractToFileNamed($test_file);

    ok(-e $test_file, "[UNICODE=$unicode] output file exists");
    is(-s $test_file, 0, "[UNICODE=$unicode] output file is empty");
}
