#!/usr/bin/perl

# See https://github.com/redhotpenguin/perl-Archive-Zip/blob/master/t/README.md
# for a short documentation on the Archive::Zip test infrastructure.

use strict;

BEGIN { $^W = 1; }

use Test::More;

use Archive::Zip qw();

use lib 't';
use common;

foreach my $pass (qw( wrong test )) {
    my $zip = Archive::Zip->new();
    isa_ok($zip, "Archive::Zip");

    azok($zip->read(dataPath("crypt.zip")), "Read file");

    ok(my @mn = $zip->memberNames, "get memberNames");
    is_deeply(\@mn, ["decrypt.txt"], "memberNames");

    ok(my $m = $zip->memberNamed($mn[0]), "find member");
    isa_ok($m, "Archive::Zip::Member");

    is($m->password($pass), $pass, "set password");
    is($m->password(),      $pass, "get password");
    is(
        $m->contents,
        $pass eq "test"
        ? "encryption test\n"
        : "",
        "Decoded buffer"
    );
}

done_testing;
