#!/usr/bin/perl

# See https://github.com/redhotpenguin/perl-Archive-Zip/blob/master/t/README.md
# for a short documentation on the Archive::Zip test infrastructure.

use strict;

BEGIN { $^W = 1; }

use Test::More tests => 4;

use Archive::Zip qw();

use lib 't';
use common;

# Check Windows Explorer compatible directories

my $zip = Archive::Zip->new;
isa_ok($zip, 'Archive::Zip');
my $member = $zip->addDirectory('foo/');
ok(defined($member), 'Created a member');
is($member->fileName, 'foo/', '->fileName ok');
ok(
    $member->externalFileAttributes & 16,
    'Directory has directory bit set as expected by Windows Explorer',
);
