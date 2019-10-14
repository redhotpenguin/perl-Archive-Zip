#!/usr/bin/perl

# Test to make sure temporal filehandles created by Archive::Zip::tempFile are closed properly

use strict;
use warnings;

use Archive::Zip;

use Test::More tests => 2;

# array to store open filhandles
my @opened_filehandles;

my $previous_tempfile_sub = \&File::Temp::tempfile;
no warnings 'redefine';
*File::Temp::tempfile = sub {
    my ( $fh, $filename ) = $previous_tempfile_sub->(@_);
    push( @opened_filehandles, $fh );
    return ( $fh, $filename );
};

# calling method
Archive::Zip::tempFile();

# testing filehandles are closed
ok( scalar @opened_filehandles == 1, "One filehandle was created" );
ok( !defined $opened_filehandles[0]
      || !defined fileno( $opened_filehandles[0] )
      || fileno( $opened_filehandles[0] ) == -1,
    "Filehandle is closed"
);
