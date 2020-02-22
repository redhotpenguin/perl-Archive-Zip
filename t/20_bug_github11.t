#!/usr/bin/perl

# See https://github.com/redhotpenguin/perl-Archive-Zip/blob/master/t/README.md
# for a short documentation on the Archive::Zip test infrastructure.

use strict;

BEGIN { $^W = 1; }

use Test::More tests => 2;

use Archive::Zip qw();

use lib 't';
use common;

# Github 11: "CRC or size mismatch" when extracting member second time
# Test for correct functionality to prevent regression

# create test env
my $GH_ISSUE   = 'github11';
my $TEST_NAME  = "20_bug_$GH_ISSUE";
my $TEST_DIR   = testPath($TEST_NAME);
mkdir($TEST_DIR) or die;

# test 1
{
my $GOOD_ZIP_FILE = dataPath("good_${GH_ISSUE}.zip");
my $GOOD_ZIP      = Archive::Zip->new($GOOD_ZIP_FILE);
my $MEMBER_FILE   = 'FILE';
my $member        = $GOOD_ZIP->memberNamed($MEMBER_FILE);
my $OUT_FILE      = testPath($TEST_DIR, "out");
# Extracting twice triggered the bug
$member->extractToFileNamed($OUT_FILE);
azok($member->extractToFileNamed($OUT_FILE), 'Testing known good zip');
}

# test 2
{
my $BAD_ZIP_FILE = dataPath("bad_${GH_ISSUE}.zip");
my $BAD_ZIP      = Archive::Zip->new($BAD_ZIP_FILE);
my $MEMBER_FILE  = 'FILE';
my $member       = $BAD_ZIP->memberNamed($MEMBER_FILE);
my $OUT_FILE     = testPath($TEST_DIR, "out");
# Extracting twice triggered the bug
$member->extractToFileNamed($OUT_FILE);
azok($member->extractToFileNamed($OUT_FILE), 'Testing known bad zip');
}
