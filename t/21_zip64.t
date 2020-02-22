#!/usr/bin/perl

# See https://github.com/redhotpenguin/perl-Archive-Zip/blob/master/t/README.md
# for a short documentation on the Archive::Zip test infrastructure.

use strict;

BEGIN { $^W = 1; }

use Test::More;

use Archive::Zip qw(:CONSTANTS :ERROR_CODES);

use lib 't';
use common;

# Test zip64 format

if (ZIP64_SUPPORTED) {
    plan(tests => 86);
} else {
    plan(skip_all => 'Zip64 format not supported.');
}

# provided by Archive::Zip 1.64 as negative example
my $ZIP64_FILE_00 = dataPath('zip64.zip');

# created by Info-Zip 3.0 as of RHEL 6
# dd if=/dev/zero bs=1KiB count=$((4 * 1024)) | zip > zip64-infozip.zip
my $ZIP64_FILE_01 = dataPath('zip64-infozip.zip');

# created by IO::Compress::Zip 2.0.2 as of Perl 5.10.1
# perl -MIO::Compress::Zip=zip -e 'my $input; open( $input, "dd if=/dev/zero bs=1KiB count=\$((4 * 1024))|" ) or die; zip( $input => "zip64-iocz.zip", Zip64 => 1) or die'
my $ZIP64_FILE_02 = dataPath('zip64-iocz.zip');

# all following created by, ahem, us
# perl -MArchive::Zip=:CONSTANTS -e 'my $zip = Archive::Zip->new(); $zip->desiredZip64Mode(ZIP64_EOCD); $zip->addString("test", "test"); $zip->writeToFileNamed("zip64-azeocd.zip")'
my $ZIP64_FILE_03 = dataPath('zip64-azeocd.zip');
# perl -MArchive::Zip=:CONSTANTS -e 'my $zip = Archive::Zip->new(); $zip->desiredZip64Mode(ZIP64_HEADERS); $zip->addString("test", "test"); $zip->writeToFileNamed("zip64-azheaders.zip")'
my $ZIP64_FILE_04 = dataPath('zip64-azheaders.zip');

my @ZIP_FILES = (
    $ZIP64_FILE_00,
    $ZIP64_FILE_01,
    $ZIP64_FILE_02,
    $ZIP64_FILE_03,
    $ZIP64_FILE_04
);

my %ZIP_MEMBERS =  (
    #                  name,      zip64, ucsize,  csize
    $ZIP64_FILE_00 => ['README',  1,     36,      36],
    $ZIP64_FILE_01 => ['-',       0,     4194304, 4080],
    $ZIP64_FILE_02 => ['',        1,     4194304, 4080],
    $ZIP64_FILE_03 => ['test',    0,     4,       4],
    $ZIP64_FILE_04 => ['test',    1,     4,       4],
);

my ($status, $output);

for my $ZIP_FILE (@ZIP_FILES) {
    my $zip = Archive::Zip->new();
    isa_ok($zip, 'Archive::Zip');
    azok($zip->read($ZIP_FILE), "Archive $ZIP_FILE");
    ok($zip->zip64(), "Zip64 flag $ZIP_FILE");
    my $info   = $ZIP_MEMBERS{$ZIP_FILE};
    my $member = $zip->memberNamed($info->[0]);
    isa_ok($member, 'Archive::Zip::ZipFileMember');
    if ($info->[1]) {
        ok($member->zip64(),                    "Member zip64 flag $ZIP_FILE");
    }
    else {
        ok(! $member->zip64(),                  "Member zip64 flag $ZIP_FILE");
    }
    is($member->uncompressedSize(), $info->[2], "Member uncompressed size $ZIP_FILE");
    is($member->compressedSize(),   $info->[3], "Member compressed size $ZIP_FILE");

    # Ensure that no zip64 extended information extra field has
    # been left in the extra fields
    my $zip64;
    my $extraFields = $member->extraFields();
    ($status, $zip64) =
        Archive::Zip::Member->_extractZip64ExtraField($extraFields, undef, undef);
    azok($status, 'Zip64 extra field extraction');
    ok(! $zip64, 'Zip64 extra field removal');

    ($output, $status) = execPerl('examples/zipinfo.pl', $ZIP_FILE);
    is($status, 0) or
        diag($output);

    ($output, $status) = execPerl('examples/ziptest.pl', $ZIP_FILE);
    is($status, 0) or
        diag($output);
}

# see also 02_main.t, which we shamelessly adapted to run most of
# its tests through all desired zip64 modes
{
    my $status;
    my $member;
    my $zip = Archive::Zip->new();
    isa_ok($zip, 'Archive::Zip');
    ok(! $zip->zip64(), 'Zip64 flag archive (pre)');

    is($zip->desiredZip64Mode(ZIP64_EOCD), ZIP64_AS_NEEDED, 'Desired zip64 mode (1)');
    is($zip->desiredZip64Mode(), ZIP64_EOCD, 'Desired zip64 mode (2)');

    $member = $zip->addDirectory('test/');
    ok(defined($member), 'Member addition');
    ok(! $member->zip64(), 'Zip64 flag member (pre)');

    azwok($zip, 'refzip' => "zip64.zip");

    ok($zip->zip64(), 'Zip64 flag archive (post)');
    ok(! $member->zip64(), 'Zip64 flag member (post)');

    $member = $zip->addString('some short test string', 'test/test');
    ok(defined($member), 'Member addition');
    ok(! $member->zip64(), 'Zip64 flag member (pre)');

    is($member->desiredZip64Mode(ZIP64_HEADERS), ZIP64_AS_NEEDED, 'Desired zip64 mode (1)');
    is($member->desiredZip64Mode(), ZIP64_HEADERS, 'Desired zip64 mode (2)');

    azwok($zip, 'refzip' => "zip64.zip");

    ok($zip->zip64(), 'Zip64 flag archive (post)');
    ok(defined($member = $zip->memberNamed('test/')), 'Member lookup');
    ok(! $member->zip64(), 'Zip64 flag member (post)');
    ok(defined($member = $zip->memberNamed('test/test')), 'Member lookup');
    ok($member->zip64(), 'Zip64 flag member (post)');
}

my $zip64ExtraField = pack('v v', 0x0001, 0);
my $uncompressedSize = 0xffffffff;
my $zip64;
($status, $zip64) =
    Archive::Zip::Member->_extractZip64ExtraField($zip64ExtraField, $uncompressedSize, undef);
azis($status, AZ_FORMAT_ERROR,
     qr/\Qinvalid zip64 extended information extra field\E/, 'Zip64 format error');
ok(! $zip64, 'Zip64 format error');
