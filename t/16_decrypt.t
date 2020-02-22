#!/usr/bin/perl

# See https://github.com/redhotpenguin/perl-Archive-Zip/blob/master/t/README.md
# for a short documentation on the Archive::Zip test infrastructure.

use strict;

BEGIN { $^W = 1; }

use Test::More tests => 8;

use Archive::Zip qw();

use lib 't';
use common;

my $zip = Archive::Zip->new();
isa_ok($zip, "Archive::Zip");
azok($zip->read(dataPath("crypcomp.zip")), "read file");

ok(my @mn = $zip->memberNames, "get memberNames");
is_deeply(\@mn, ["test"], "memberNames");
ok(my $m = $zip->memberNamed($mn[0]), "find member");
isa_ok($m, "Archive::Zip::Member");

is($m->password("test"), "test", "correct password");
is($m->contents, "encryption test\n" x 100, "decoded buffer");
