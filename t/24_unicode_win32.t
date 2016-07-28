#!/usr/bin/perl

# tests with $Archive::Zip::UNICODE
use utf8;       #utf8 source code
use strict;

BEGIN {
    $|  = 1;
    $^W = 1;
}
use Test::More;
use Archive::Zip;

use File::Temp;
use File::Path;
use File::Spec;

use lib 't';
use common;

#Initialy written for MSWin32 only, but I found a bug in memberNames() so
# other systems should be tested too.
#if( $^O ne 'MSWin32' ) {
#    plan skip_all => 'Test relevant only on MSWin32';
#    done_testing();
#    exit;
#}

$Archive::Zip::UNICODE=1;

mkpath([File::Spec->catdir(TESTDIR, 'folder')]);
my $euro_filename = "euro-€";
my $zero_file = File::Spec->catfile(TESTDIR, 'folder', $euro_filename);
open(EURO, ">$zero_file");
print EURO "File EURO\n";
close(EURO);

# create member called $euro_filename with addTree
{
    my $archive = Archive::Zip->new;
    $archive->addTree(File::Spec->catfile(TESTDIR, 'folder'), 'folder',);
    
    #TEST
    is_deeply(
        [ $archive->memberNames()],
        [ "folder/", "folder/$euro_filename" ],
        "Checking that a file named with unicode chars was added properly"
    );

}

# create member called $euro_filename with addString
{
    # Create member $euro_filename with addString
    my $archive = Archive::Zip->new;
    my $string_member = $archive->addString(TESTSTRING => $euro_filename);
    $archive->writeToFileNamed(OUTPUTZIP);
}
#TEST
{
    # Read member $euro_filename
    my $archive = Archive::Zip->new;
    is($archive->read(OUTPUTZIP), Archive::Zip::AZ_OK);
    is_deeply(
        [$archive->memberNames()],
        [$euro_filename],
        "Checking that a file named with unicode chars was added properly by addString");
}
unlink(OUTPUTZIP);

{
    # Create member called $euro_filename with addFile
    # use a temp file so it's name doesn't match internal name
    my $tmp_file = File::Temp->new;
    $tmp_file->print("File EURO\n");
    $tmp_file->flush;
    my $archive = Archive::Zip->new;
    my $string_member = $archive->addFile($tmp_file->filename => $euro_filename);
    $archive->writeToFileNamed(OUTPUTZIP);
}
#TEST
{
    # Read member $euro_filename
    my $archive = Archive::Zip->new;
    is($archive->read(OUTPUTZIP), Archive::Zip::AZ_OK);
    is_deeply(
        [$archive->memberNames()],
        [$euro_filename],
        "Checking that a file named with unicode chars was added properly by addFile");
}
unlink(OUTPUTZIP);

{
    # Create member called $euro_filename with addDirectory
    my $archive = Archive::Zip->new;
    my $string_member = $archive->addDirectory(
        File::Spec->catdir(TESTDIR, 'folder') => $euro_filename);
    $archive->writeToFileNamed(OUTPUTZIP);
}
#TEST
{
    # Read member $euro_filename
    my $archive = Archive::Zip->new;
    is($archive->read(OUTPUTZIP), Archive::Zip::AZ_OK);
    is_deeply(
        [$archive->memberNames()],
        [$euro_filename.'/'],
        "Checking that a file named with unicode chars was added properly by addDirectory");
}
unlink(OUTPUTZIP);

{
    # Create member called $euro_filename with addFileOrDirectory from a directory
    my $archive = Archive::Zip->new;
    my $string_member = $archive->addFileOrDirectory(
        File::Spec->catdir(TESTDIR, 'folder') => $euro_filename);
    $archive->writeToFileNamed(OUTPUTZIP);
}
#TEST
{
    # Read member $euro_filename
    my $archive = Archive::Zip->new;
    is($archive->read(OUTPUTZIP), Archive::Zip::AZ_OK);
    is_deeply(
        [$archive->memberNames()],
        [$euro_filename.'/'],
        "Checking that a file named with unicode chars was added properly by addFileOrDirectory from a direcotry");
}
unlink(OUTPUTZIP);

{
    # Create member called $euro_filename with addFileOrDirectory from a file
    # use a temp file so it's name doesn't match internal name
    my $tmp_file = File::Temp->new;
    $tmp_file->print("File EURO\n");
    $tmp_file->flush;    
    my $archive = Archive::Zip->new;
    my $string_member = $archive->addFileOrDirectory(
        $tmp_file->filename => $euro_filename);
    $archive->writeToFileNamed(OUTPUTZIP);
}
#TEST
{
    # Read member $euro_filename
    my $archive = Archive::Zip->new;
    is($archive->read(OUTPUTZIP), Archive::Zip::AZ_OK);
    is_deeply(
        [$archive->memberNames()],
        [$euro_filename],
        "Checking that a file named with unicode chars was added properly by addFileOrDirectory from a file");
}
unlink(OUTPUTZIP);

rmtree([File::Spec->catdir(TESTDIR, 'folder')]);
done_testing();