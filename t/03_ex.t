#!/usr/bin/perl

# See https://github.com/redhotpenguin/perl-Archive-Zip/blob/master/t/README.md
# for a short documentation on the Archive::Zip test infrastructure.

use strict;

BEGIN { $^W = 1; }

use Test::More tests => 18;

use Archive::Zip qw();

use lib 't';
use common;

# Test example scripts

use constant FILENAME  => testPath('testing.txt');
use constant ZFILENAME => testPath('testing.txt', PATH_ZIPFILE);

my $zip = Archive::Zip->new();
isa_ok($zip, 'Archive::Zip');
isa_ok($zip->addString(TESTSTRING, ZFILENAME), 'Archive::Zip::StringMember');
azok($zip->writeToFileNamed(INPUTZIP));

my ($status, $output);

($output, $status) = execPerl('examples/copy.pl', INPUTZIP, OUTPUTZIP);
is($status, 0) or diag($output);

($output, $status) = execPerl('examples/extract.pl', OUTPUTZIP, ZFILENAME);
is($status, 0) or diag($output);

($output, $status) = execPerl('examples/mfh.pl', INPUTZIP);
is($status, 0) or diag($output);

($output, $status) = execPerl('examples/zip.pl', OUTPUTZIP, INPUTZIP, FILENAME);
is($status, 0) or diag($output);

($output, $status) = execPerl('examples/zipinfo.pl', INPUTZIP);
if (is($status, 0)) {
  note($output);
} else {
  diag($output);
}

($output, $status) = execPerl('examples/ziptest.pl', INPUTZIP);
if (is($status, 0)) {
  note($output);
} else {
  diag($output);
}

($output, $status) = execPerl('examples/zipGrep.pl', '100', INPUTZIP);
is($status, 0);
is($output, ZFILENAME . ":100\n");

unlink(OUTPUTZIP);
($output, $status) = execPerl('examples/selfex.pl', OUTPUTZIP, FILENAME);
is($status, 0) or diag($output);
unlink(FILENAME);
($output, $status) = execPerl(OUTPUTZIP, testPath());
is($status, 0) or diag($output);
my $fn = testPath(FILENAME);
is(-f $fn, 1, "$fn exists");

unlink(OUTPUTZIP);
($output, $status) = execPerl('examples/updateTree.pl', OUTPUTZIP, testPath());
is($status, 0, "updateTree.pl create") or diag($output);
is(-f OUTPUTZIP, 1, "zip created");
($output, $status) = execPerl('examples/updateTree.pl', OUTPUTZIP, testPath());
is($status, 0, "updateTree.pl update") or diag($output);
is(-f OUTPUTZIP, 1, "zip updated");
unlink(OUTPUTZIP);

# Still untested:
#
# calcSizes.pl - creates test.zip, may be sensitive to /dev/null
# mailZip.pl
# readScalar.pl - requires IO::Scalar
# unzipAll.pl
# updateZip.pl
# writeScalar2.pl
# writeScalar.pl
# zipcheck.pl
# ziprecent.pl
