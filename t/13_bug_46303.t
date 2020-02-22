#!/usr/bin/perl

use strict;

BEGIN {
    $|  = 1;
    $^W = 1;
}
use Archive::Zip;
use Test::More tests => 4;
use lib 't';
use common;

my $zip = Archive::Zip->new();
isa_ok($zip, 'Archive::Zip');
azok($zip->read(dataPath('perl.zip')), 'Read file');

azok($zip->extractTree(undef, testPath()), 'Extracted archive');
ok(-d testPath('foo'), 'Checked directory');
