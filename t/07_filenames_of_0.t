#!/usr/bin/perl

# See https://github.com/redhotpenguin/perl-Archive-Zip/blob/master/t/README.md
# for a short documentation on the Archive::Zip test infrastructure.

use strict;

BEGIN { $^W = 1; }

use Test::More tests => 14;

use Archive::Zip qw();

use lib 't';
use common;

# These are regression tests for:
# http://rt.cpan.org/Public/Bug/Display.html?id=27463
# http://rt.cpan.org/Public/Bug/Display.html?id=76780
#
# It tests that one can add files to the archive whose filenames are "0".

# Try to create member called "0" with addTree
{
    mkdir(testPath('folder')) or die;

    my $zero_file = testPath('folder', '0');
    open(O, ">$zero_file") or die;
    print O "File 0\n";
    close(O);

    my $one_file = testPath('folder', '1');
    open(O, ">$one_file") or die;
    print O "File 1\n";
    close(O);

    my $archive = Archive::Zip->new;
    isa_ok($archive, 'Archive::Zip');

    azok($archive->addTree(testPath('folder'), 'folder'));

    # TEST
    ok(scalar(grep { $_ eq "folder/0" } $archive->memberNames()),
       "Checking that a file called '0' was added properly by addTree");
}

# Try to create member called "0" with addString
{
    my $archive = Archive::Zip->new;
    isa_ok($archive, 'Archive::Zip');
    isa_ok($archive->addString((TESTSTRING) => 0), 'Archive::Zip::StringMember');
    azwok($archive, 'file' => OUTPUTZIP);
}

# Try to find member called "0" with memberNames
{
    my $archive = Archive::Zip->new;
    isa_ok($archive, 'Archive::Zip');
    azok($archive->read(OUTPUTZIP));
    ok(scalar(grep { $_ eq "0" } $archive->memberNames()),
       "Checking that a file called '0' was added properly by addString");
}
