#!/usr/bin/perl

use strict;

BEGIN {
    $|  = 1;
    $^W = 1;
}

use Test::More tests => 4;
use File::Spec;
use File::Path;
use Archive::Zip qw(:CONSTANTS);

use t::common;

#101240: Possible issue with zero length files on Win32 when UNICODE is enabled


my $test_dir = File::Spec->catdir(TESTDIR, "empty");
my $input_file = File::Spec->catfile($test_dir, "empty.zip");
mkpath($test_dir);

{
    # Create a zip file that contains a member where compressed size is 0

    my $zip = Archive::Zip->new();
    my $string_member = $zip->addString( '', 'fred' );
    $string_member->desiredCompressionMethod( COMPRESSION_STORED );
    $zip->writeToFileNamed($input_file) ;
}

for my $unicode (0, 1)
{
    local $Archive::Zip::UNICODE = $unicode;

    my $zip = Archive::Zip->new();

    $zip->read($input_file);

    my $test_file = File::Spec->catfile($test_dir, "test_file$unicode");

    $zip->memberNamed("fred")->extractToFileNamed($test_file);

    # TEST
    ok -e $test_file, "[UNICODE=$unicode] output file exists";
    is -s $test_file, 0, "[UNICODE=$unicode] output file is empty";

    # Clean up.
    #unlink $test_file;
}

#rmtree($test_dir);
