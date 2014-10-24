#!/usr/bin/perl

use strict;

BEGIN {
    $|  = 1;
    $^W = 1;
}

use Archive::Zip qw( :ERROR_CODES );
use Test::More tests => 4;

use lib qw(. t/lib);
use test::common;

my $zip = Archive::Zip->new();
isa_ok($zip, 'Archive::Zip');
is($zip->read('t/data/perl.zip'), AZ_OK, 'Read file');

is($zip->extractTree(undef, File::Spec->catpath('', TESTDIR, 'xTree', '')), AZ_OK, 'Extracted archive');
ok(-d File::Spec->catpath('', TESTDIR, 'xTree/foo', 'Checked directory'));
