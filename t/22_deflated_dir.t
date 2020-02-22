#!/usr/bin/perl

use strict;
use warnings;

use Archive::Zip;
use File::Spec;
use lib 't';
use common;

use Test::More tests => 8;

my $zip = Archive::Zip->new();
isa_ok( $zip, 'Archive::Zip' );
azok( $zip->read(dataPath('jar.zip')), 'Read file' );
azwok( $zip );
