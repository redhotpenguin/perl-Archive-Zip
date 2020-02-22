#!/usr/bin/perl

# See https://github.com/redhotpenguin/perl-Archive-Zip/blob/master/t/README.md
# for a short documentation on the Archive::Zip test infrastructure.

use strict;

BEGIN { $^W = 1; }

use Test::More tests => 2;

use lib 't';
use common;

use_ok('Archive::Zip');
use_ok('Archive::Zip::MemberRead');

common::azuzdiag();
common::azuztdiag();
common::azwpdiag();
