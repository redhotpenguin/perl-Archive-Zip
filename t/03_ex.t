#!/usr/bin/perl

use strict;

BEGIN {
    $|  = 1;
    $^W = 1;
}

use Archive::Zip qw( :ERROR_CODES :CONSTANTS );
use File::Spec;
use IO::File;
use File::Temp qw(tempfile tempdir);
use Test::More tests => 17;

use lib qw(. t/lib);
use test::common;


sub runPerlCommand {
    my $path = $ENV{"PATH"};
    $ENV{"PATH"} = '';
    my $libs   = join(' -I', @INC);
    my $cmd    = "\"$^X\" \"-I$libs\" -w \"" . join('" "', @_) . '"';
    my $output = `$cmd`;
    $ENV{"PATH"} = $path;
    return wantarray ? ($?, $output) : $?;
}

use constant FILENAME => 
    (tempfile('test03-XXXXX', SUFFIX => '.txt', DIR => TESTDIR, UNLINK => 1))[1];
use constant ZFILENAME => File::Spec->catfile(FILENAME);    # name in zip

my $zip = Archive::Zip->new();
isa_ok($zip, 'Archive::Zip');

$zip->addString(File::Spec->catfile(TESTSTRING), File::Spec->catfile(FILENAME));
$zip->writeToFileNamed(File::Spec->catfile(INPUTZIP));

my ($status, $output);
my $fh = IO::File->new("test.log", "w");
isa_ok($fh, 'IO::File');

is(runPerlCommand(File::Spec->catfile('examples', 'copy.pl'), File::Spec->catfile(INPUTZIP), File::Spec->catfile(OUTPUTZIP)), 0);

is(runPerlCommand(File::Spec->catfile('examples','extract.pl'), File::Spec->catfile(OUTPUTZIP), ZFILENAME), 0);

is(runPerlCommand(File::Spec->catfile('examples','mfh.pl'), File::Spec->catfile(INPUTZIP)), 0);

is(runPerlCommand(File::Spec->catfile('examples','zip.pl'), File::Spec->catfile(OUTPUTZIP), File::Spec->catfile(INPUTZIP), File::Spec->catfile(FILENAME)), 0);

($status, $output) = runPerlCommand(File::Spec->catfile('examples','zipinfo.pl'), File::Spec->catfile(INPUTZIP));
is($status, 0);
$fh->print("zipinfo output:\n");
$fh->print($output);

($status, $output) = runPerlCommand(File::Spec->catfile('examples','ziptest.pl'), File::Spec->catfile(INPUTZIP));
is($status, 0);
$fh->print("ziptest output:\n");
$fh->print($output);

($status, $output) = runPerlCommand(File::Spec->catfile('examples','zipGrep.pl'), '100', File::Spec->catfile(INPUTZIP));
is($status, 0);
is(File::Spec->catfile($output), ZFILENAME . ":100\n");

# calcSizes.pl
# creates test.zip, may be sensitive to /dev/null

# removed because requires IO::Scalar
# ok( runPerlCommand('examples/readScalar.pl'), 0 );

unlink(File::Spec->catfile(OUTPUTZIP));
is(runPerlCommand(File::Spec->catfile('examples','selfex.pl'), File::Spec->catfile(OUTPUTZIP), File::Spec->catfile(FILENAME)), 0);
unlink(File::Spec->catfile(FILENAME));

is(runPerlCommand(OUTPUTZIP), 0);
my $fn = File::Spec->catfile(TESTDIR,FILENAME);
is(-f $fn, 1, "$fn exists");

# unzipAll.pl
# updateZip.pl
# writeScalar.pl
# zipcheck.pl
# ziprecent.pl

unlink(File::Spec->catfile(OUTPUTZIP));
is(runPerlCommand(File::Spec->catfile('examples','updateTree.pl'), File::Spec->catfile(OUTPUTZIP), File::Spec->catfile(TESTDIR)),
    0, "updateTree.pl create");
is(-f File::Spec->catfile(OUTPUTZIP), 1, "zip created");

is(runPerlCommand(File::Spec->catfile('examples','updateTree.pl'), File::Spec->catfile(OUTPUTZIP), File::Spec->catfile(TESTDIR)),
    0, "updateTree.pl update");
is(-f File::Spec->catfile(OUTPUTZIP), 1, "zip updated");
unlink(File::Spec->catfile(OUTPUTZIP));
