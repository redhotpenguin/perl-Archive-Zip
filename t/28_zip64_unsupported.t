#!/usr/bin/perl

use strict;
use warnings;

use Archive::Zip qw( :CONSTANTS :ERROR_CODES );
use File::Spec;
use Test::More;
use lib 't';
use common;

# Test proper detection of unsupportedness of zip64 format

if ($Archive::Zip::_ZIP64_NOT_SUPPORTED) {
   plan(tests => 3);
} else {
    plan(skip_all => 'Zip64 format is supported.');
}

my $DATA_DIR  = File::Spec->catfile('t', 'data');

my $ZIP64_FILE = File::Spec->catfile($DATA_DIR, 'zip64.zip');

my @errors = ();
local $Archive::Zip::ErrorHandler = sub { push @errors, @_ };

my $zip = Archive::Zip->new();
isa_ok($zip, 'Archive::Zip');
is($zip->read($ZIP64_FILE), AZ_ERROR, "Archive $ZIP64_FILE");
ok($errors[0] =~ /\Qzip64 format not supported on this Perl interpreter\E/);
