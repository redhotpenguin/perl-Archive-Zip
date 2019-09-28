#!/usr/bin/perl

use strict;
use warnings;

use Archive::Zip qw( :CONSTANTS :ERROR_CODES );
use File::Spec;
use Test::More;
use lib 't';
use common;

# Test proper detection of unsupportedness of zip64 format

if (ZIP64_SUPPORTED) {
    plan(skip_all => 'Zip64 format is supported.');
} else {
    plan(tests => 13);
}

my $DATA_DIR  = File::Spec->catfile('t', 'data');

my $ZIP64_FILE = File::Spec->catfile($DATA_DIR, 'zip64.zip');

my @errors = ();

local $Archive::Zip::ErrorHandler = sub { push @errors, @_ };

my $zip;

# trigger error in _readEndOfCentralDirectory
@errors = ();
$zip = Archive::Zip->new();
isa_ok($zip, 'Archive::Zip');
is($zip->read($ZIP64_FILE), AZ_ERROR);
ok($errors[0] =~ /\Qzip64 format not supported on this Perl interpreter\E/);

# trigger error in _writeEndOfCentralDirectory
@errors = ();
$zip = Archive::Zip->new();
$zip->desiredZip64Mode(ZIP64_EOCD);
isa_ok($zip, 'Archive::Zip');
is($zip->writeToFileNamed(OUTPUTZIP), AZ_ERROR);
ok($errors[0] =~ /\Qzip64 format not supported on this Perl interpreter\E/);

# trigger error in _writeLocalFileHeader
@errors = ();
$zip = Archive::Zip->new();
$zip->desiredZip64Mode(ZIP64_HEADERS);
isa_ok($zip, 'Archive::Zip');
isa_ok($zip->addString("foo", "bar"), 'Archive::Zip::StringMember');
is($zip->writeToFileNamed(OUTPUTZIP), AZ_ERROR);
ok($errors[0] =~ /\Qzip64 format not supported on this Perl interpreter\E/);

# trigger error in _extractZip64ExtraField
@errors = ();
my $zip64ExtraField = pack('v v', 0x0001, 0);
my $member = Archive::Zip::Member->newFromString(TESTSTRING);
ok(defined($member));
is($member->cdExtraField($zip64ExtraField), AZ_ERROR);
ok($errors[0] =~ /\Qzip64 format not supported on this Perl interpreter\E/);
