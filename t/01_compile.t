#!/usr/bin/perl

use strict;
use warnings;
BEGIN {
    $| = 1;
}

use Test::More tests => 2;

use_ok('Archive::Zip');
use_ok('Archive::Zip::MemberRead');
