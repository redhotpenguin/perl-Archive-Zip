#!/usr/bin/perl

# See https://github.com/redhotpenguin/perl-Archive-Zip/blob/master/t/README.md
# for a short documentation on the Archive::Zip test infrastructure.

use strict;

BEGIN { $^W = 1; }

use Test::More tests => 2;

use Archive::Zip qw();

use lib 't';
use common;

# Test to make sure temporal filehandles created by Archive::Zip::tempFile are closed properly

# array to store open filhandles
my @opened_filehandles;

my $previous_tempfile_sub = \&File::Temp::tempfile;
no warnings 'redefine';
*File::Temp::tempfile = sub {
    my ($fh, $filename) = $previous_tempfile_sub->(@_);
    push(@opened_filehandles, $fh);
    return ($fh, $filename);
};

# calling method
Archive::Zip::tempFile();

# testing filehandles are closed
ok(scalar(@opened_filehandles == 1), "One filehandle was created");
ok(   !defined $opened_filehandles[0]
   || !defined fileno($opened_filehandles[0])
   || fileno($opened_filehandles[0]) == -1,
   "Filehandle is closed");
