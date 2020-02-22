#!/usr/bin/perl

# See https://github.com/redhotpenguin/perl-Archive-Zip/blob/master/t/README.md
# for a short documentation on the Archive::Zip test infrastructure.

use strict;

BEGIN { $^W = 1; }

use Test::More tests => 8;

use Archive::Zip qw();

use lib 't';
use common;

# Test Archive::Zip::addTree

my $zip;
my @memberNames;

sub makeZip {
    my ($src, $dest, $pred) = @_;
    $zip = Archive::Zip->new();
    $zip->addTree($src, $dest, $pred);
    @memberNames = $zip->memberNames();
}

sub makeZipAndLookFor {
    my ($src, $dest, $pred, $lookFor) = @_;
    local $Test::Builder::Level = $Test::Builder::Level + 1;
    makeZip($src, $dest, $pred);
    ok(@memberNames);
    ok((grep { $_ eq $lookFor } @memberNames) == 1)
        or diag("Can't find $lookFor in (" . join(",", @memberNames) . ")");
}

makeZipAndLookFor('.', '',   sub { note "file $_";
                                   -f && /\.t$/ },       't/02_main.t');
makeZipAndLookFor('.', 'e/', sub { -f && /\.t$/ },       'e/t/02_main.t');
makeZipAndLookFor('t', '',   sub { -f && /\.t$/ },       '02_main.t');
makeZipAndLookFor('t', 'e/', sub { -f && /\.t$/ || -d }, 'e/data/');
