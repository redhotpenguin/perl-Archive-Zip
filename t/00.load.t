#!perl -T

use Test::More tests => 2;

use_ok( 'Archive::Zip' );
use_ok( 'Archive::Zip::MemberRead' );
diag( "Testing Archive::Zip $Archive::Zip::VERSION, Perl $], $^X" );

