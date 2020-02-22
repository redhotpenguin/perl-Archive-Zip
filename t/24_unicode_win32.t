#!/usr/bin/perl

# See https://github.com/redhotpenguin/perl-Archive-Zip/blob/master/t/README.md
# for a short documentation on the Archive::Zip test infrastructure.

use strict;

# need utf8 source code
use utf8;

BEGIN { $^W = 1; }

use File::Temp;
use Test::More tests => 48;

use Archive::Zip qw();

use lib 't';
use common;

# Initialy written for MSWin32 only, but I found a bug in memberNames() so
# other systems should be tested too.

$Archive::Zip::UNICODE = 1;

# create and test archive
sub cata
{
    my ($creator, $membernames, $name) = @_;

    local $Test::Builder::Level = $Test::Builder::Level + 1;

    # create and write archive
    {
        my $archive = Archive::Zip->new;
        &$creator($archive);
        azwok($archive, 'name' => $name);
    }

    # read archive and test member names
    {
        my $archive = Archive::Zip->new;
        azok($archive->read(OUTPUTZIP), "$name - test read");
        is_deeply([$archive->memberNames()], $membernames, "$name - test members");
    }

    unlink(OUTPUTZIP) or die;
}

my $euro_filename = "euro-€";
{
    mkdir(testPath('folder')) or die;
    open(my $euro_file, ">", testPath('folder', $euro_filename)) or die;
    print $euro_file "File EURO\n" or die;
    close($euro_file) or die;
}

# create member called $euro_filename with addTree
cata(sub { $_[0]->addTree(testPath('folder'), 'folder') },
     ["folder/", "folder/$euro_filename"],
     "Checking that a file named with unicode chars was added properly by addTree");

# create member called $euro_filename with addString
cata(sub { $_[0]->addString(TESTSTRING => $euro_filename) },
     [$euro_filename],
     "Checking that a file named with unicode chars was added properly by addString");

# create member called $euro_filename with addFile
# use a temp file so its name doesn't match internal name
cata(sub { my ($tmp_file, $tmp_filename) =
               File::Temp::tempfile('eurotest-XXXX', DIR => testPath());
           $tmp_file->print("File EURO\n") or die;
           $tmp_file->close() or die;
           $_[0]->addFile($tmp_filename => $euro_filename); },
     [$euro_filename],
     "Checking that a file named with unicode chars was added properly by addFile");

# create member called $euro_filename with addDirectory
cata(sub { $_[0]->addDirectory(testPath('folder') => $euro_filename) },
     [$euro_filename . '/'],
     "Checking that a file named with unicode chars was added properly by addDirectory");

# create member called $euro_filename with addFileOrDirectory from a directory
cata(sub { $_[0]->addFileOrDirectory(testPath('folder') => $euro_filename) },
     [$euro_filename . '/'],
     "Checking that a file named with unicode chars was added properly by addFileOrDirectory from a direcotry");

# create member called $euro_filename with addFileOrDirectory from a file
# use a temp file so its name doesn't match internal name
cata(sub { my ($tmp_file, $tmp_filename) =
               File::Temp::tempfile('eurotest-XXXX', DIR => testPath());
           $tmp_file->print("File EURO\n") or die;
           $tmp_file->close() or die;
           $_[0]->addFileOrDirectory($tmp_filename => $euro_filename); },
     [$euro_filename],
     "Checking that a file named with unicode chars was added properly by addFileOrDirectory from a file");
