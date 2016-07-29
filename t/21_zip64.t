#!/usr/bin/perl

# Test to make sure zip64 files are properly detected

use strict;
use warnings;

use Archive::Zip qw( :ERROR_CODES );
use File::Spec;
use lib 't';
use common;

use Test::More tests => 1;

my $DATA_DIR = File::Spec->catfile('t', 'data');
my $ZIP_FILE = File::Spec->catfile($DATA_DIR, "zip64.zip");

my @errors = ();
$Archive::Zip::ErrorHandler = sub { push @errors, @_ };
eval { Archive::Zip->new($ZIP_FILE) };
ok($errors[0] =~ /zip64 not supported/, 'Got expected zip64 error');
