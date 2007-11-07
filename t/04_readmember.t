#!/usr/bin/perl

use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}
use Archive::Zip qw( :ERROR_CODES :CONSTANTS );
use Archive::Zip::MemberRead;

use Test::More tests => 8;
BEGIN {
    unshift @INC, "t/"; 
    require( File::Spec->catfile('t', 'common.pl') )
		or die "Can't load t/common.pl";
}

use constant FILENAME => File::Spec->catfile(TESTDIR, 'member_read.zip');

my ($zip, $member, $fh, @data);
$zip  = new Archive::Zip;
isa_ok( $zip, 'Archive::Zip' );
@data = ( 'Line 1', 'Line 2', '', 'Line 3', 'Line 4' );

$zip->addString(join("\n", @data), 'string.txt');
$zip->writeToFileNamed(FILENAME);

$member = $zip->memberNamed('string.txt');
$fh     = $member->readFileHandle();
ok( $fh );

my ($line, $not_ok, $ret, $buffer);
while ( defined($line = $fh->getline()) ) {
	$not_ok = 1 if ($line ne $data[$fh->input_line_number()-1]);
}
SKIP: {
	if ( $^O eq 'MSWin32' ) {
		skip("Ignoring failing test on Win32", 1);
	}
	ok( !$not_ok );
}

$fh->rewind();
$ret = $fh->read($buffer, length($data[0]));
ok( $ret == length($data[0]) );
ok( $buffer eq $data[0] );
$fh->close();

#
# Different usages 
#
$fh = new Archive::Zip::MemberRead($zip, 'string.txt');
ok($fh);

$fh = new Archive::Zip::MemberRead($zip, $zip->memberNamed('string.txt'));
ok($fh);

$fh = new Archive::Zip::MemberRead($zip->memberNamed('string.txt'));
ok($fh);
