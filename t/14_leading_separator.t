#!/usr/bin/perl

# See https://github.com/redhotpenguin/perl-Archive-Zip/blob/master/t/README.md
# for a short documentation on the Archive::Zip test infrastructure.

use strict;

BEGIN { $^W = 1; }

use File::Spec::Unix;
use File::Spec;
use Test::More tests => 3;

use Archive::Zip qw();

use lib 't';
use common;

# Test the bug-fix for the following bug:
# Buggy behaviour:
#     Adding file or directory by absolute path results in leading separator
#     being stored in member name.
# Expected behaviour:
#     Discard leading separator
# Bug report: http://tech.groups.yahoo.com/group/perl-beginner/message/27085

my $file_absolute_path = testPath('file.txt', PATH_ABS);
open FH, ">$file_absolute_path" or die;
close FH;

my $az = Archive::Zip->new();
isa_ok($az, 'Archive::Zip');
isa_ok($az->addFile($file_absolute_path), 'Archive::Zip::FileMember');

# expect path without leading separator
(my $expected_member_name = testPath('file.txt', PATH_ZIPABS)) =~ s{^/}{};
my ($member_name) = $az->memberNames();
is($member_name, $expected_member_name, 'no leading separator');
