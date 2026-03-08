#!/usr/bin/perl

# Test that Archive::Zip works when supplied a filename that is an object which
# stringifies (such as from Path::Tiny or Path::Class).

use strict;
use feature qw<say>;

BEGIN {
    $|  = 1;
    $^W = 1;
}
use Archive::Zip qw( :ERROR_CODES );
use Test::More tests => 3;

# A simple object which uses overloading to behave as a string:
{
  package FileObj;
  use overload q[""] => sub { $_[0]{name} };
  sub new { bless {name => $_[1]}, $_[0] }
}

my $zip = Archive::Zip->new();
my $filename_string = 't/data/perl.zip';
my $filename_obj = FileObj->new($filename_string);
open my $filehandle, '<', $filename_string
    or die "Opening $filename_string failed: $!";

is($zip->read($filename_string), AZ_OK, 'Read from filename as string');
is($zip->read($filename_obj   ), AZ_OK, 'Read from filename as object');
is($zip->read($filehandle     ), AZ_OK, 'Read from filehandle'        );
