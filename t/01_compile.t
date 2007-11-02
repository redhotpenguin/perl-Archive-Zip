#!/usr/bin/perl

use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}
use Test::More tests => 2;

use_ok( 'Archive::Zip' );
use_ok( 'Archive::Zip::MemberRead' );
