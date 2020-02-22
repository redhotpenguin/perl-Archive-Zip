#!/usr/bin/perl

# See https://github.com/redhotpenguin/perl-Archive-Zip/blob/master/t/README.md
# for a short documentation on the Archive::Zip test infrastructure.

use strict;

BEGIN { $^W = 1; }

use File::Path;
use Test::More;

use Archive::Zip qw(:ERROR_CODES :CONSTANTS);

use lib 't';
use common;

#####################################################################
# Testing Utility Functions

#--------- check CRC
is(TESTSTRINGCRC, 0xac373f32, 'Testing CRC matches expected');

{
    my @errors = ();
    local $Archive::Zip::ErrorHandler = sub { push @errors, @_ };
    eval { Archive::Zip::Member::_unixToDosTime(0) };
    ok($errors[0] =~ /Tried to add member with zero or undef value for time/,
        'Got expected _unixToDosTime error');
}

#--------- check time conversion

foreach my $unix_time (
    315576062,  315576064,  315580000,  315600000,
    316000000,  320000000,  400000000,  500000000,
    600000000,  700000000,  800000000,  900000000,
    1000000000, 1100000000, 1200000000, int(time() / 2) * 2,
  ) {
    my $dos_time   = Archive::Zip::Member::_unixToDosTime($unix_time);
    my $round_trip = Archive::Zip::Member::_dosToUnixTime($dos_time);
    is($unix_time, $round_trip, 'Got expected DOS DateTime value');
}

#####################################################################
# Testing Archives

# Enjoy the non-indented freedom!
for my $desiredZip64Mode (ZIP64_AS_NEEDED, ZIP64_EOCD, ZIP64_HEADERS) {

next unless ZIP64_SUPPORTED || $desiredZip64Mode == ZIP64_AS_NEEDED;

# Re-create test directory for each loop iteration
rmtree([testPath()], 0, 0);
mkdir(testPath()) or die;

#--------- empty file
# new	# Archive::Zip
# new	# Archive::Zip::Archive
my $zip = Archive::Zip->new();
isa_ok($zip, 'Archive::Zip');

$zip->desiredZip64Mode($desiredZip64Mode);

# members	# Archive::Zip::Archive
my @members = $zip->members;
is(scalar(@members), 0, '->members is 0');

# numberOfMembers	# Archive::Zip::Archive
my $numberOfMembers = $zip->numberOfMembers();
is($numberOfMembers, 0, '->numberofMembers is 0');

# writeToFileNamed	# Archive::Zip::Archive
azok($zip->writeToFileNamed(OUTPUTZIP), '->writeToFileNamed ok');

azuztok(refzip => "emptyzip.zip");

#--------- add a directory
my $memberName = testPath(PATH_ZIPDIR);
my $dirName    = testPath();

# addDirectory	# Archive::Zip::Archive
# new	# Archive::Zip::Member
my $member = $zip->addDirectory($memberName);
ok(defined($member));
is($member->fileName(), $memberName);

# On some (Windows systems) the modification time is
# corrupted. Save this to check later.
my $dirTime = $member->lastModFileDateTime();

# members	# Archive::Zip::Archive
@members = $zip->members();
is(scalar(@members), 1);
is($members[0],      $member);

# numberOfMembers	# Archive::Zip::Archive
$numberOfMembers = $zip->numberOfMembers();
is($numberOfMembers, 1);

# writeToFileNamed	# Archive::Zip::Archive
azok($zip->writeToFileNamed(OUTPUTZIP));

# Does the modification time get corrupted?
is(($zip->members)[0]->lastModFileDateTime(), $dirTime);

azuztok();

#--------- extract the directory by name
rmdir($dirName) or die;
azok($zip->extractMember($memberName));
ok(-d $dirName);

#--------- extract the directory by identity
rmdir($dirName) or die;
azok($zip->extractMember($member));
ok(-d $dirName);

#--------- add a string member, uncompressed
$memberName = testPath('string.txt', PATH_ZIPFILE);

# addString	# Archive::Zip::Archive
# newFromString	# Archive::Zip::Member
$member = $zip->addString(TESTSTRING, $memberName);
ok(defined($member));

is($member->fileName(), $memberName);

# members	# Archive::Zip::Archive
@members = $zip->members();
is(scalar(@members), 2);
is($members[1],      $member);

# numberOfMembers	# Archive::Zip::Archive
$numberOfMembers = $zip->numberOfMembers();
is($numberOfMembers, 2);

# writeToFileNamed	# Archive::Zip::Archive
azok($zip->writeToFileNamed(OUTPUTZIP));

azuztok();

is($member->crc32(), TESTSTRINGCRC);

is($member->crc32String(), sprintf("%08x", TESTSTRINGCRC));

#--------- extract it by name
azok($zip->extractMember($memberName));
ok  (-f $memberName);
is  (readFile($memberName), TESTSTRING);

#--------- now compress it and re-test
my $oldCompressionMethod =
  $member->desiredCompressionMethod(COMPRESSION_DEFLATED);
is($oldCompressionMethod, COMPRESSION_STORED, 'old compression method OK');

# writeToFileNamed	# Archive::Zip::Archive
azok($zip->writeToFileNamed(OUTPUTZIP), 'writeToFileNamed returns AZ_OK');
is  ($member->crc32(),            TESTSTRINGCRC);
is  ($member->uncompressedSize(), TESTSTRINGLENGTH);

azuztok();

#--------- extract it by name
azok($zip->extractMember($memberName));
ok  (-f $memberName);
is  (readFile($memberName), TESTSTRING);

#--------- add a file member, compressed
ok(rename($memberName, testPath('file.txt', PATH_ZIPFILE)));
$memberName = testPath('file.txt', PATH_ZIPFILE);

# addFile	# Archive::Zip::Archive
# newFromFile	# Archive::Zip::Member
$member = $zip->addFile($memberName);
ok(defined($member));

is($member->desiredCompressionMethod(), COMPRESSION_DEFLATED);

# writeToFileNamed	# Archive::Zip::Archive
azok($zip->writeToFileNamed(OUTPUTZIP));
is  ($member->crc32(),            TESTSTRINGCRC);
is  ($member->uncompressedSize(), TESTSTRINGLENGTH);

azuztok();

#--------- extract it by name (note we have to rename it first
#--------- or we will clobber the original file
my $newName = $memberName;
$newName =~ s/\.txt/2.txt/;
azok($zip->extractMember($memberName, $newName));
ok  (-f $newName);
is  (readFile($newName), TESTSTRING);

#--------- now make it uncompressed and re-test
$oldCompressionMethod = $member->desiredCompressionMethod(COMPRESSION_STORED);

is($oldCompressionMethod, COMPRESSION_DEFLATED);

# writeToFileNamed	# Archive::Zip::Archive
azok($zip->writeToFileNamed(OUTPUTZIP));
is  ($member->crc32(),            TESTSTRINGCRC);
is  ($member->uncompressedSize(), TESTSTRINGLENGTH);

azuztok();

#--------- extract it by name
azok($zip->extractMember($memberName, $newName));
ok  (-f $newName);
is  (readFile($newName), TESTSTRING);

# Now, the contents of OUTPUTZIP are:
# Length   Method    Size  Ratio   Date   Time   CRC-32    Name
#--------  ------  ------- -----   ----   ----   ------    ----
#       0  Stored        0   0%  03-17-00 11:16  00000000  testDir/
#     300  Defl:N      146  51%  03-17-00 11:16  ac373f32  testDir/string.txt
#     300  Stored      300   0%  03-17-00 11:16  ac373f32  testDir/file.txt
#--------          -------  ---                            -------
#     600              446  26%                            3 files

# members	# Archive::Zip::Archive
@members = $zip->members();
is(scalar(@members), 3);
is($members[2],      $member);

# memberNames	# Archive::Zip::Archive
my @memberNames = $zip->memberNames();
is(scalar(@memberNames), 3);
is($memberNames[2],      $memberName);

# memberNamed	# Archive::Zip::Archive
is($zip->memberNamed($memberName), $member);

# membersMatching	# Archive::Zip::Archive
@members = $zip->membersMatching('file');
is(scalar(@members), 1);
is($members[0],      $member);

@members = $zip->membersMatching('.txt$');
is(scalar(@members), 2);
is($members[1],      $member);

#--------- remove the string member and test the file
# removeMember	# Archive::Zip::Archive
$member = $zip->removeMember($members[0]);
is($member, $members[0]);

azwok($zip);

#--------- add the string member at the end and test the file
# addMember	# Archive::Zip::Archive
$zip->addMember($member);
@members = $zip->members();

is(scalar(@members), 3);
is($members[2],      $member);

# memberNames	# Archive::Zip::Archive
@memberNames = $zip->memberNames();
is(scalar(@memberNames), 3);
is($memberNames[1],      $memberName);

azwok($zip);

#--------- remove the file member
$member = $zip->removeMember($members[1]);
is($member,                 $members[1]);
is($zip->numberOfMembers(), 2);

#--------- replace the string member with the file member
# replaceMember	# Archive::Zip::Archive
$member = $zip->replaceMember($members[2], $member);
is($member,                 $members[2]);
is($zip->numberOfMembers(), 2);

#--------- re-add the string member
$zip->addMember($member);
is($zip->numberOfMembers(), 3);

azwok($zip);

#--------- add compressed file
$member = $zip->addFile(testPath('file.txt'));
ok(defined($member));
$member->desiredCompressionMethod(COMPRESSION_DEFLATED);
$member->fileName(testPath('fileC.txt', PATH_ZIPFILE));

#--------- add uncompressed string
$member = $zip->addString(TESTSTRING, testPath('stringU.txt', PATH_ZIPFILE));
ok(defined($member));
$member->desiredCompressionMethod(COMPRESSION_STORED);

# Now, the file looks like this:
# Length   Method    Size  Ratio   Date   Time   CRC-32    Name
#--------  ------  ------- -----   ----   ----   ------    ----
#       0  Stored        0   0%  03-17-00 12:30  00000000  testDir/
#     300  Stored      300   0%  03-17-00 12:30  ac373f32  testDir/file.txt
#     300  Defl:N      146  51%  03-17-00 12:30  ac373f32  testDir/string.txt
#     300  Stored      300   0%  03-17-00 12:30  ac373f32  testDir/stringU.txt
#     300  Defl:N      146  51%  03-17-00 12:30  ac373f32  testDir/fileC.txt
#--------          -------  ---                            -------
#    1200              892  26%                            5 files

@members         = $zip->members();
$numberOfMembers = $zip->numberOfMembers();
is($numberOfMembers, 5);

#--------- make sure the contents of the stored file member are OK.
# contents	# Archive::Zip::Archive
is($zip->contents($members[1]), TESTSTRING);

# contents	# Archive::Zip::Member
is($members[1]->contents(), TESTSTRING);

#--------- make sure the contents of the compressed string member are OK.
is($members[2]->contents(), TESTSTRING);

#--------- make sure the contents of the stored string member are OK.
is($members[3]->contents(), TESTSTRING);

#--------- make sure the contents of the compressed file member are OK.
is($members[4]->contents(), TESTSTRING);

#--------- write to INPUTZIP
azwok($zip, 'file' => INPUTZIP);

#--------- read from INPUTZIP (appending its entries)
# read	# Archive::Zip::Archive
azok($zip->read(INPUTZIP));
is  ($zip->numberOfMembers(), 10);

#--------- clean up duplicate names
@members = $zip->members();
$member  = $zip->removeMember($members[5]);
is($member->fileName(), testPath(PATH_ZIPDIR));

SCOPE: {
    for my $i (6 .. 9) {
        $memberName = $members[$i]->fileName();
        $memberName =~ s/\.txt/2.txt/;
        $members[$i]->fileName($memberName);
    }
}
is(scalar($zip->membersMatching('2.txt')), 4);

#--------- write zip out and test it.
azwok($zip);

#--------- Make sure that we haven't renamed files (this happened!)
is(scalar($zip->membersMatching('2\.txt$')), 4);

#--------- Now try extracting everyone
@members = $zip->members();
azok($zip->extractMember($members[0]));    #DM
azok($zip->extractMember($members[1]));    #NFM
azok($zip->extractMember($members[2]));
azok($zip->extractMember($members[3]));    #NFM
azok($zip->extractMember($members[4]));
azok($zip->extractMember($members[5]));
azok($zip->extractMember($members[6]));
azok($zip->extractMember($members[7]));
azok($zip->extractMember($members[8]));

#--------- count dirs
{
    my @dirs = grep { $_->isDirectory() } @members;
    is(scalar(@dirs), 1);
    is($dirs[0],      $members[0]);
}

#--------- count binary and text files
{
    my @binaryFiles = grep { $_->isBinaryFile() } @members;
    my @textFiles   = grep { $_->isTextFile() } @members;
    is(scalar(@binaryFiles), 5);
    is(scalar(@textFiles),   4);
}

#--------- Try writing zip file to file handle
my $fh;
ok  ($fh = azopen(OUTPUTZIP), 'Pipe open');
azok($zip->writeToFileHandle($fh), 'Write zip to file handle');
ok  ($fh->close(), 'Pipe close');

azuztok();

#--------- Change the contents of a string member
my $status;
is(ref($members[2]), 'Archive::Zip::StringMember');
(undef, $status) = $members[2]->contents("This is my new contents\n");
azok($status);

#--------- write zip out and test it.
azwok($zip);

#--------- Change the contents of a file member
is(ref($members[1]), 'Archive::Zip::NewFileMember');
(undef, $status) = $members[1]->contents("This is my new contents\n");
azok($status);

#--------- write zip out and test it.
azwok($zip);

#--------- Change the contents of a zip member

is(ref($members[7]), 'Archive::Zip::ZipFileMember');
(undef, $status) = $members[7]->contents("This is my new contents\n");
azok($status);

#--------- write zip out and test it.
azwok($zip);

}

#####################################################################
# Testing Member Methods

#--------- Test methods related to extra fields

my $inv0ExtraField  = pack('v',           0x000d);
my $inv1ExtraField  = pack('v v V V v',   0x000d, 12, 0, 0, 0);
my $unx0ExtraField  = pack('v v V V v v', 0x000d, 12, 0, 0, 0, 0);
my $unx1ExtraField  = pack('v v V V v v', 0x000d, 12, 1, 1, 1, 1);
my $zip64ExtraField = pack('v v',         0x0001,  0);

# cdExtraField                  # Archive::Zip::Member
# _extractZip64ExtraField       # Archive::Zip::Member

#--------- Non-error cases

my $member = Archive::Zip::Member->newFromString(TESTSTRING);
ok  (defined($member));
is  ($member->cdExtraField(), '');
azok($member->cdExtraField($unx0ExtraField));
is  ($member->cdExtraField(), $unx0ExtraField);
azok($member->cdExtraField(''));
is  ($member->cdExtraField(), '');

#--------- Error cases

{
    azis($member->cdExtraField($inv0ExtraField), AZ_FORMAT_ERROR,
         qr/\Qinvalid extra field (bad header ID or data size)\E/);
    is  ($member->cdExtraField(), '');

    azis($member->cdExtraField($inv1ExtraField), AZ_FORMAT_ERROR,
         qr/\Qinvalid extra field (bad data)\E/);
    is  ($member->cdExtraField(), '');

    SKIP: {
        skip("zip64 format not supported", 2)
            unless ZIP64_SUPPORTED;
        azis($member->cdExtraField($zip64ExtraField), AZ_FORMAT_ERROR,
             qr/\Qinvalid extra field (contains zip64 information)\E/);
        is  ($member->cdExtraField(), '');
    }
}

# localExtraField               # Archive::Zip::Member
# _extractZip64ExtraField       # Archive::Zip::Member

#--------- Non-error cases

$member = Archive::Zip::Member->newFromString(TESTSTRING);
ok  (defined($member));
is  ($member->localExtraField(), '');
azok($member->localExtraField($unx0ExtraField));
is  ($member->localExtraField(), $unx0ExtraField);
azok($member->localExtraField(''));
is  ($member->localExtraField(), '');

#--------- Error cases

{
    azis($member->localExtraField($inv0ExtraField), AZ_FORMAT_ERROR,
         qr/\Qinvalid extra field (bad header ID or data size)\E/);
    is  ($member->localExtraField(), '');

    azis($member->localExtraField($inv1ExtraField), AZ_FORMAT_ERROR,
         qr/\Qinvalid extra field (bad data)\E/);
    is  ($member->localExtraField(), '');

    SKIP: {
        skip("zip64 format not supported", 2)
            unless ZIP64_SUPPORTED;
        azis($member->localExtraField($zip64ExtraField), AZ_FORMAT_ERROR,
             qr/\Qinvalid extra field (contains zip64 information)\E/);
        is  ($member->localExtraField(), '');
    }
}

# extraFields   # Archive::Zip::Member
azok($member->localExtraField($unx0ExtraField));
azok($member->cdExtraField($unx1ExtraField));
is  ($member->extraFields(), "$unx0ExtraField$unx1ExtraField");

#--------------------- STILL UNTESTED IN THIS SCRIPT ---------------------

# sub setChunkSize	# Archive::Zip
# sub _formatError	# Archive::Zip
# sub _error	# Archive::Zip
# sub _subclassResponsibility 	# Archive::Zip
# sub diskNumber	# Archive::Zip::Archive
# sub diskNumberWithStartOfCentralDirectory	# Archive::Zip::Archive
# sub numberOfCentralDirectoriesOnThisDisk	# Archive::Zip::Archive
# sub numberOfCentralDirectories	# Archive::Zip::Archive
# sub centralDirectoryOffsetWRTStartingDiskNumber	# Archive::Zip::Archive
# sub isEncrypted	# Archive::Zip::Member
# sub isTextFile	# Archive::Zip::Member
# sub isBinaryFile	# Archive::Zip::Member
# sub isDirectory	# Archive::Zip::Member
# sub lastModTime	# Archive::Zip::Member
# sub _writeDataDescriptor	# Archive::Zip::Member
# sub isDirectory	# Archive::Zip::DirectoryMember
# sub _becomeDirectory	# Archive::Zip::DirectoryMember
# sub diskNumberStart	# Archive::Zip::ZipFileMember

done_testing();
