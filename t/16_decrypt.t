#!/usr/bin/perl

use strict;
use warnings;

BEGIN { $| = 1; }

use Archive::Zip;
use Test::More;
use lib 't';
use common;

my $zip = Archive::Zip->new();
isa_ok($zip, "Archive::Zip");
azok($zip->read(dataPath("crypcomp.zip")), "Read file");

ok(my @mn = $zip->memberNames, "get memberNames");
is_deeply(\@mn, ["test"], "memberNames");
ok(my $m = $zip->memberNamed($mn[0]), "find member");
isa_ok($m, "Archive::Zip::Member");

is($m->password("test"), "test", "correct password");
is($m->contents, "encryption test\n" x 100, "Decoded buffer");

done_testing;
