#!perl -T

use Test::More tests => 2;

use_ok( 'Archive::Zip' );
use_ok( 'Archive::Zip::MemberRead' );
# Commenting out distracting clutter
# diag( "Testing Archive::Zip $Archive::Zip::VERSION, Perl $], $^X" );

