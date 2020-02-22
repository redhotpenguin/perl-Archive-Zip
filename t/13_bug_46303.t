#!/usr/bin/perl

# See https://github.com/redhotpenguin/perl-Archive-Zip/blob/master/t/README.md
# for a short documentation on the Archive::Zip test infrastructure.

use strict;

BEGIN { $^W = 1; }

use Test::More tests => 4;

use Archive::Zip qw();

use lib 't';
use common;

# Ensure method Archive::Zip::extractTree operates correctly even
# if the destination directory name does not end in a slash.

my $zip = Archive::Zip->new();
isa_ok($zip, 'Archive::Zip');
azok($zip->read(dataPath('perl.zip')), 'Read file');

azok($zip->extractTree(undef, testPath(PATH_ZIPFILE)), 'Extracted archive');
ok(-d testPath('foo'), 'Checked directory');
