#!/usr/bin/perl

# See https://github.com/redhotpenguin/perl-Archive-Zip/blob/master/t/README.md
# for a short documentation on the Archive::Zip test infrastructure.

use strict;

BEGIN { $^W = 1; }

use Test::More;

use Archive::Zip qw(:CONSTANTS :ERROR_CODES);

use lib 't';
use common;

# Test proper detection of unsupportedness of zip64 format

if (ZIP64_SUPPORTED) {
    plan(skip_all => 'Zip64 format is supported.');
} else {
    plan(tests => 9);
}

# trigger error in _readEndOfCentralDirectory
my $zip = Archive::Zip->new();
isa_ok($zip, 'Archive::Zip');
azis($zip->read(dataPath('zip64.zip')), AZ_ERROR,
     qr/\Qzip64 format not supported on this Perl interpreter\E/);

# trigger error in _writeEndOfCentralDirectory
$zip = Archive::Zip->new();
$zip->desiredZip64Mode(ZIP64_EOCD);
isa_ok($zip, 'Archive::Zip');
azis($zip->writeToFileNamed(OUTPUTZIP), AZ_ERROR,
     qr/\Qzip64 format not supported on this Perl interpreter\E/);

# trigger error in _writeLocalFileHeader
$zip = Archive::Zip->new();
$zip->desiredZip64Mode(ZIP64_HEADERS);
isa_ok($zip, 'Archive::Zip');
isa_ok($zip->addString("foo", "bar"), 'Archive::Zip::StringMember');
azis($zip->writeToFileNamed(OUTPUTZIP), AZ_ERROR,
     qr/\Qzip64 format not supported on this Perl interpreter\E/);

# trigger error in _extractZip64ExtraField
my $zip64ExtraField = pack('v v', 0x0001, 0);
my $member = Archive::Zip::Member->newFromString(TESTSTRING);
ok(defined($member));
azis($member->cdExtraField($zip64ExtraField), AZ_ERROR,
     qr/\Qzip64 format not supported on this Perl interpreter\E/);
