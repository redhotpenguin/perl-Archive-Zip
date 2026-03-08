#!/usr/bin/perl

# This demonstrates how using Archive::Zip::readFromFileHandle and Archive::Zip::overwriteAs
# can avoid an open system call for every existing member of a zip file, when compared to
# using Archive::Zip::read and Archive::Zip::overwrite .

use strict;
use warnings;
use Archive::Zip qw( AZ_OK COMPRESSION_DEFLATED );
use IO::File;
use Carp qw( croak );

my $test_zip_file = 'nights.zip';
unlink $test_zip_file;
{
    my $zip = Archive::Zip->new();
    for ( 1 .. 1000 ) {
        my $member = $zip->addString( "night_$_", "night_$_" );
        $member->desiredCompressionMethod(COMPRESSION_DEFLATED);
    }
    ($zip->writeToFileNamed($test_zip_file) == AZ_OK) or croak;
}

my $z = Archive::Zip->new();
if ( $ENV{'USE_FH'} ) {
    my $fh = IO::File->new( $test_zip_file, 'r' ) or croak;
    ($z->readFromFileHandle($fh) == AZ_OK) or croak;
    my $member = $z->addString( 'night_1001', 'night_1001' );
    $member->desiredCompressionMethod(COMPRESSION_DEFLATED);
    ($z->overwriteAs($test_zip_file) == AZ_OK) or croak;
}
else {
    ($z->read($test_zip_file) == AZ_OK) or croak;
    my $member = $z->addString( 'night_1001', 'night_1001' );
    $member->desiredCompressionMethod(COMPRESSION_DEFLATED);
    ($z->overwrite() == AZ_OK) or croak;
}

# When run without the environment variable USE_FH set,
# read and overwrite methods are used and strace shows over 1000
# open system calls for the file nights.zip .
#   When run with the environment variable USE_FH set,
# readFromFileHandle and overwriteAs methods are used and strace
# shows only 3 open system calls for the file nights.zip .

# With simulated slow opens:

# strace -cw -e trace=open -e inject=open:delay_enter=10000 -P nights.zip perl AvoidOpens.pl
# % time     seconds  usecs/call     calls    errors syscall
# 100.00   10.288955       10258      1003           open

# USE_FH=1 strace -cw -e trace=open -e inject=open:delay_enter=10000 -P nights.zip perl AvoidOpens.pl
# % time     seconds  usecs/call     calls    errors syscall
# 100.00    0.032818       10939         3           open
