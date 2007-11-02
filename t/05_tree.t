#!/usr/bin/perl

use strict;

use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}
use Archive::Zip qw( :ERROR_CODES :CONSTANTS );
use FileHandle;
use File::Spec;

use Test::More tests =>6;
BEGIN {
    unshift @INC, "t/"; 
    require( File::Spec->catfile('t', 'common.pl') )
		or die "Can't load t/common.pl";
}

use constant FILENAME => File::Spec->catfile(TESTDIR, 'testing.txt');

my $zip;
my @memberNames;

sub makeZip
{
	my ($src, $dest, $pred) = @_;
	$zip = Archive::Zip->new();
	$zip->addTree($src, $dest, $pred);
	@memberNames = $zip->memberNames();
}

sub makeZipAndLookFor
{
	my ($src, $dest, $pred, $lookFor) = @_;
	makeZip($src, $dest, $pred);
	ok( @memberNames );
	ok( (grep { $_ eq $lookFor } @memberNames) == 1 )
		or print STDERR "Can't find $lookFor in (" . join(",", @memberNames) . ")\n";
}

my ($testFileVolume, $testFileDirs, $testFileName) = File::Spec->splitpath($0);

makeZipAndLookFor('.', '', sub { print "file $_\n"; -f && /\.t$/ }, 't/02_main.t' );
makeZipAndLookFor('.', 'e/', sub { -f && /\.t$/ }, 'e/t/02_main.t');
makeZipAndLookFor('./t', '', sub { -f && /\.t$/ }, '02_main.t' );
