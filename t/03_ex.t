#!/usr/bin/perl

use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}
use Archive::Zip qw( :ERROR_CODES :CONSTANTS );
use File::Spec;
use IO::File;

use Test::More tests => 17;
BEGIN {
    unshift @INC, "t/"; 
    require( File::Spec->catfile('t', 'common.pl') )
		or die "Can't load t/common.pl";
}

sub runPerlCommand
{
	my $libs = join ( ' -I', @INC );
	my $cmd    = "\"$^X\" \"-I$libs\" -w \"". join('" "', @_). '"';
	my $output = `$cmd`;
	return wantarray ? ( $?, $output ) : $?;
}

use constant FILENAME => File::Spec->catpath( '', TESTDIR, 'testing.txt' );
use constant ZFILENAME => TESTDIR . "/testing.txt"; # name in zip

my $zip = Archive::Zip->new();
isa_ok( $zip, 'Archive::Zip' );
$zip->addString( TESTSTRING, FILENAME );
$zip->writeToFileNamed(INPUTZIP);

my ( $status, $output );
my $fh = IO::File->new( "test.log", "w" );
isa_ok( $fh, 'IO::File' );

is( runPerlCommand( 'examples/copy.pl', INPUTZIP, OUTPUTZIP ), 0 );

is( runPerlCommand( 'examples/extract.pl', OUTPUTZIP, ZFILENAME ), 0 );

is( runPerlCommand( 'examples/mfh.pl', INPUTZIP ), 0 );

is( runPerlCommand( 'examples/zip.pl', OUTPUTZIP, INPUTZIP, FILENAME ), 0 );

( $status, $output ) = runPerlCommand( 'examples/zipinfo.pl', INPUTZIP );
is( $status, 0 );
$fh->print("zipinfo output:\n");
$fh->print($output);

( $status, $output ) = runPerlCommand( 'examples/ziptest.pl', INPUTZIP );
is( $status, 0 );
$fh->print("ziptest output:\n");
$fh->print($output);

( $status, $output ) = runPerlCommand( 'examples/zipGrep.pl', '100', INPUTZIP );
is( $status, 0 );
is( $output, ZFILENAME . ":100\n" );

# calcSizes.pl
# creates test.zip, may be sensitive to /dev/null

# removed because requires IO::Scalar
# ok( runPerlCommand('examples/readScalar.pl'), 0 );

unlink(OUTPUTZIP);
is( runPerlCommand( 'examples/selfex.pl', OUTPUTZIP, FILENAME ), 0 );
unlink(FILENAME);
is( runPerlCommand(OUTPUTZIP), 0 );
my $fn =
  File::Spec->catpath( '', File::Spec->catdir( 'extracted', TESTDIR ),
	'testing.txt' );
is( -f $fn, 1, "$fn exists" );

# unzipAll.pl
# updateZip.pl
# writeScalar.pl
# zipcheck.pl
# ziprecent.pl

unlink(OUTPUTZIP);
is( runPerlCommand( 'examples/updateTree.pl', OUTPUTZIP, TESTDIR ), 0, "updateTree.pl create" );
is( -f OUTPUTZIP, 1, "zip created" );
is( runPerlCommand( 'examples/updateTree.pl', OUTPUTZIP, TESTDIR ), 0, "updateTree.pl update" );
is( -f OUTPUTZIP, 1, "zip updated" );
unlink(OUTPUTZIP);
