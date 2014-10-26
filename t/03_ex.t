#!/usr/bin/perl

use strict;
use warnings;
BEGIN {
    $| = 1;
}

use Archive::Zip qw( :ERROR_CODES :CONSTANTS );
use File::Spec;
use IO::File;
use File::Temp qw(tempfile tempdir);
use Test::More tests => 17;

use lib 't/lib';
use test::common;

sub runPerlCommand {
    # Sanity checks that satisfy taint.
    # May be best to hardcode the example/scripts.pl here
    # in a whitelist instead.
    my $blacklist = qr/([^$%;|]+)/;
    my $argClean  = sub{ (my $x = $_[0]) =~ s/"/\"/g; $x };
    my @libs = map { '"-Mlib=' . $argClean->($_) . '"' } grep(/$blacklist/, @INC);
    my @args = map { '"'       . $argClean->($_) . '"' } grep(/$blacklist/, @_  );

    my $path      = $ENV{"PATH"};
    $ENV{"PATH"}  = ''; # -T %ENV not needed for backtick/system call

    # It would be better if we could use: system(PERLPATH,@libs,@args)
    # but test: is($output, ZFILENAME . ":100\n"); relies on both the 
    # exit code and the output. All other tests pass with system $cmd LIST
    my $libString = join(' ', @libs);
    my $argString = join(' ', @args);
    my $cmd = '"'.PERLPATH.'"' . ' ' . $libString . ' -w ' . $argString;
    my $output = `$cmd`;

    $ENV{"PATH"} = $path;
    return wantarray ? ($?, $output) : $?;
}

use constant FILENAME =>
    File::Spec->catfile((tempfile('test03-XXXXX', SUFFIX => '.txt', DIR => TESTDIR, UNLINK => 1))[1]);

my $zip = Archive::Zip->new();
isa_ok($zip, 'Archive::Zip');

$zip->addString(TESTSTRING, FILENAME);
$zip->writeToFileNamed(INPUTZIP);

my ($status, $output);
my $fh = IO::File->new("test.log", "w");
isa_ok($fh, 'IO::File');

is(runPerlCommand('examples/copy.pl', INPUTZIP, OUTPUTZIP), 0);

is(runPerlCommand('examples/extract.pl', OUTPUTZIP, FILENAME), 0);

is(runPerlCommand('examples/mfh.pl', INPUTZIP), 0);

is(runPerlCommand('examples/zip.pl', OUTPUTZIP, INPUTZIP, FILENAME), 0);

($status, $output) = runPerlCommand('examples/zipinfo.pl', INPUTZIP);
is($status, 0);
$fh->print("zipinfo output:\n");
$fh->print($output);

($status, $output) = runPerlCommand('examples/ziptest.pl', INPUTZIP);
is($status, 0);
$fh->print("ziptest output:\n");
$fh->print($output);

($status, $output) = runPerlCommand('examples/zipGrep.pl', '100', INPUTZIP);
is($status, 0);
is(File::Spec->catfile($output), FILENAME . ":100\n"); # or should File::Spec be used on zipGrep.pl return value?

# calcSizes.pl
# creates test.zip, may be sensitive to /dev/null

# removed because requires IO::Scalar
# ok( runPerlCommand('examples/readScalar.pl'), 0 );

unlink(OUTPUTZIP);
is(runPerlCommand('examples/selfex.pl', OUTPUTZIP, FILENAME), 0);
unlink(FILENAME);
is(runPerlCommand(OUTPUTZIP), 0);
my $fn = FILENAME;
is(-f $fn, 1, "$fn exists");

# unzipAll.pl
# updateZip.pl
# writeScalar.pl
# zipcheck.pl
# ziprecent.pl

unlink(OUTPUTZIP);
is(runPerlCommand('examples/updateTree.pl', OUTPUTZIP, TESTDIR),
    0, "updateTree.pl create");
is(-f OUTPUTZIP, 1, "zip created");

is(runPerlCommand('examples/updateTree.pl', OUTPUTZIP, TESTDIR),
    0, "updateTree.pl update");
is(-f OUTPUTZIP, 1, "zip updated");
unlink(OUTPUTZIP);
