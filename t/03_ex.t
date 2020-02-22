#!/usr/bin/perl

use strict;

BEGIN {
    $|  = 1;
    $^W = 1;
}
use Archive::Zip qw( :ERROR_CODES :CONSTANTS );
use File::Spec;
use IO::File;

use Test::More tests => 16;
use lib 't';
use common;

use constant FILENAME  => testPath('testing.txt');
use constant ZFILENAME => testPath('testing.txt', PATH_ZIPFILE);

my $zip = Archive::Zip->new();
isa_ok($zip, 'Archive::Zip');
$zip->addString(TESTSTRING, FILENAME);
$zip->writeToFileNamed(INPUTZIP);

my ($status, $output);

($output, $status) = execPerl('examples/copy.pl', INPUTZIP, OUTPUTZIP);
is($status, 0) or
    diag($output);

($output, $status) = execPerl('examples/extract.pl', OUTPUTZIP, ZFILENAME);
is($status, 0) or
    diag($output);

($output, $status) = execPerl('examples/mfh.pl', INPUTZIP);
is($status, 0) or
    diag($output);

($output, $status) = execPerl('examples/zip.pl', OUTPUTZIP, INPUTZIP, FILENAME);
is($status, 0) or
    diag($output);

($output, $status) = execPerl('examples/zipinfo.pl', INPUTZIP);
is($status, 0) or
    diag($output);

($output, $status) = execPerl('examples/ziptest.pl', INPUTZIP);
is($status, 0) or
    diag($output);

($output, $status) = execPerl('examples/zipGrep.pl', '100', INPUTZIP);
is($status, 0);
is($output, ZFILENAME . ":100\n");

# calcSizes.pl
# creates test.zip, may be sensitive to /dev/null

# removed because requires IO::Scalar
# ok( execPerl('examples/readScalar.pl'), 0 );

unlink(OUTPUTZIP);
is(execPerl('examples/selfex.pl', OUTPUTZIP, FILENAME), 0);
unlink(FILENAME);
is(execPerl(OUTPUTZIP, testPath()), 0);
my $fn = testPath(FILENAME);
is(-f $fn, 1, "$fn exists");

# unzipAll.pl
# updateZip.pl
# writeScalar.pl
# zipcheck.pl
# ziprecent.pl

unlink(OUTPUTZIP);
is(execPerl('examples/updateTree.pl', OUTPUTZIP, TESTDIR),
    0, "updateTree.pl create");
is(-f OUTPUTZIP, 1, "zip created");
is(execPerl('examples/updateTree.pl', OUTPUTZIP, TESTDIR),
    0, "updateTree.pl update");
is(-f OUTPUTZIP, 1, "zip updated");
unlink(OUTPUTZIP);
