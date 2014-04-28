#!/usr/bin/perl

use strict;
use warnings;

BEGIN { $| = 1; }

use Archive::Zip qw( :ERROR_CODES );
use Test::More;

foreach my $pass (qw( wrong test )) {
    my $zip = Archive::Zip->new();
    isa_ok($zip, "Archive::Zip");

    is($zip->read("t/data/crypt.zip"), AZ_OK, "Read file");

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
