#!/usr/bin/perl

# Main testing for Archive::Zip

use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}

use Archive::Zip qw( :ERROR_CODES :CONSTANTS );
use FileHandle;
use File::Path;
use File::Spec;

use Test::More tests => 141;

BEGIN {
    unshift @INC, "t/"; 
    require( File::Spec->catfile('t', 'common.pl') )
		or die "Can't load t/common.pl";
}





#####################################################################
# Testing Utility Functions

#--------- check CRC
is( TESTSTRINGCRC, 0xac373f32, 'Testing CRC matches expected' );

# Bad times die
SCOPE: {
	my @errors = ();
	local $Archive::Zip::ErrorHandler = sub { push @errors, @_ };
	eval { Archive::Zip::Member::_unixToDosTime( 0 ) };
	ok( $errors[0] =~ /Tried to add member with zero or undef/,
		'Got expected _unixToDosTime error' );
}

#--------- check time conversion

foreach my $unix_time (
	315576062, 315576064, 315580000, 315600000,
	316000000, 320000000, 400000000, 500000000,
	600000000, 700000000, 800000000, 900000000,
	1000000000, 1100000000, 1200000000,
	int(time()/2)*2,
) {
	my $dos_time   = Archive::Zip::Member::_unixToDosTime( $unix_time );
	my $round_trip = Archive::Zip::Member::_dosToUnixTime( $dos_time  );
	is( $unix_time, $round_trip, 'Got expected DOS DateTime value' );
}





#####################################################################
# Testing Archives

#--------- empty file
# new	# Archive::Zip
# new	# Archive::Zip::Archive
my $zip = Archive::Zip->new();
isa_ok( $zip, 'Archive::Zip' );

# members	# Archive::Zip::Archive
my @members = $zip->members;
is(scalar(@members), 0, '->members is 0' );

# numberOfMembers	# Archive::Zip::Archive
my $numberOfMembers = $zip->numberOfMembers();
is($numberOfMembers, 0, '->numberofMembers is 0' );

# writeToFileNamed	# Archive::Zip::Archive
my $status = $zip->writeToFileNamed( OUTPUTZIP );
is($status, AZ_OK, '->writeToFileNames ok' );

my $zipout;
SKIP: {
	skip( "No 'unzip' program to test against", 1 ) unless HAVEUNZIP;
	if ( $^O eq 'MSWin32' ) {
		print STDERR "\n# You might see an expected 'zipfile is empty' warning now.\n";
	}
	($status, $zipout) = testZip();
	# STDERR->print("status= $status, out=$zipout\n");

	skip( "test zip doesn't work", 1 ) if $testZipDoesntWork;
	ok( $status != 0 );
}
# unzip -t returns error code=1 for warning on empty

#--------- add a directory
my $memberName = TESTDIR . '/';
my $dirName = TESTDIR;

# addDirectory	# Archive::Zip::Archive
# new	# Archive::Zip::Member
my $member = $zip->addDirectory($memberName);
ok(defined($member));
is($member->fileName(), $memberName);

# On some (Windows systems) the modification time is
# corrupted. Save this to check late.
my $dir_time = $member->lastModFileDateTime();

# members	# Archive::Zip::Archive
@members = $zip->members();
is(scalar(@members), 1);
is($members[0], $member);

# numberOfMembers	# Archive::Zip::Archive
$numberOfMembers = $zip->numberOfMembers();
is($numberOfMembers, 1);

# writeToFileNamed	# Archive::Zip::Archive
$status = $zip->writeToFileNamed( OUTPUTZIP );
is($status, AZ_OK);

# Does the modification time get corrupted?
is( ($zip->members)[0]->lastModFileDateTime(), $dir_time );

SKIP: {
	skip( "No 'unzip' program to test against", 1 ) unless HAVEUNZIP;
	($status, $zipout) = testZip();
	# STDERR->print("status= $status, out=$zipout\n");
	skip( "test zip doesn't work", 1 ) if $testZipDoesntWork;
	is( $status, 0 );
}

#--------- extract the directory by name
rmtree([ TESTDIR ], 0, 0);
$status = $zip->extractMember($memberName);
is($status, AZ_OK);
ok(-d $dirName);

#--------- extract the directory by identity
ok(rmdir($dirName));	# it's still empty
$status = $zip->extractMember($member);
is($status, AZ_OK);
ok(-d $dirName);

#--------- add a string member, uncompressed
$memberName = TESTDIR . '/string.txt';
# addString	# Archive::Zip::Archive
# newFromString	# Archive::Zip::Member
$member = $zip->addString(TESTSTRING, $memberName);
ok(defined($member));

is($member->fileName(), $memberName);

# members	# Archive::Zip::Archive
@members = $zip->members();
is(scalar(@members), 2);
is($members[1], $member);

# numberOfMembers	# Archive::Zip::Archive
$numberOfMembers = $zip->numberOfMembers();
is($numberOfMembers, 2);

# writeToFileNamed	# Archive::Zip::Archive
$status = $zip->writeToFileNamed( OUTPUTZIP );
is($status, AZ_OK);

SKIP: {
	skip( "No 'unzip' program to test against", 1 ) unless HAVEUNZIP;
	($status, $zipout) = testZip();
	# STDERR->print("status= $status, out=$zipout\n");
	skip( "test zip doesn't work", 1 ) if $testZipDoesntWork;
	is( $status, 0 );
}

is($member->crc32(), TESTSTRINGCRC);

is($member->crc32String(), sprintf("%08x", TESTSTRINGCRC));

#--------- extract it by name
$status = $zip->extractMember($memberName);
is($status, AZ_OK);
ok(-f $memberName);
is(fileCRC($memberName), TESTSTRINGCRC);

#--------- now compress it and re-test
my $oldCompressionMethod = 
	$member->desiredCompressionMethod(COMPRESSION_DEFLATED);
is($oldCompressionMethod, COMPRESSION_STORED, 'old compression method OK');

# writeToFileNamed	# Archive::Zip::Archive
$status = $zip->writeToFileNamed( OUTPUTZIP );
is($status, AZ_OK, 'writeToFileNamed returns AZ_OK');
is($member->crc32(), TESTSTRINGCRC);
is($member->uncompressedSize(), TESTSTRINGLENGTH);

SKIP: {
	skip( "No 'unzip' program to test against", 1 ) unless HAVEUNZIP;
	($status, $zipout) = testZip();
	# STDERR->print("status= $status, out=$zipout\n");
	skip( "test zip doesn't work", 1 ) if $testZipDoesntWork;
	is( $status, 0 );
}

#--------- extract it by name
$status = $zip->extractMember($memberName);
is($status, AZ_OK);
ok(-f $memberName);
is(fileCRC($memberName), TESTSTRINGCRC);

#--------- add a file member, compressed
ok(rename($memberName, TESTDIR . '/file.txt'));
$memberName = TESTDIR . '/file.txt';

# addFile	# Archive::Zip::Archive
# newFromFile	# Archive::Zip::Member
$member = $zip->addFile($memberName);
ok(defined($member));

is($member->desiredCompressionMethod(), COMPRESSION_DEFLATED);

# writeToFileNamed	# Archive::Zip::Archive
$status = $zip->writeToFileNamed( OUTPUTZIP );
is($status, AZ_OK);
is($member->crc32(), TESTSTRINGCRC);
is($member->uncompressedSize(), TESTSTRINGLENGTH);

SKIP: {
	skip( "No 'unzip' program to test against", 1 ) unless HAVEUNZIP;
	($status, $zipout) = testZip();
	# STDERR->print("status= $status, out=$zipout\n");
	skip( "test zip doesn't work", 1 ) if $testZipDoesntWork;
	is( $status, 0 );
}

#--------- extract it by name (note we have to rename it first
#--------- or we will clobber the original file
my $newName = $memberName;
$newName =~ s/\.txt/2.txt/;
$status = $zip->extractMember($memberName, $newName);
is($status, AZ_OK);
ok(-f $newName);
is(fileCRC($newName), TESTSTRINGCRC);

#--------- now make it uncompressed and re-test
$oldCompressionMethod =
	$member->desiredCompressionMethod(COMPRESSION_STORED);

is($oldCompressionMethod, COMPRESSION_DEFLATED);

# writeToFileNamed	# Archive::Zip::Archive
$status = $zip->writeToFileNamed( OUTPUTZIP );
is($status, AZ_OK);
is($member->crc32(), TESTSTRINGCRC);
is($member->uncompressedSize(), TESTSTRINGLENGTH);

SKIP: {
	skip( "No 'unzip' program to test against", 1 ) unless HAVEUNZIP;
	($status, $zipout) = testZip();
	# STDERR->print("status= $status, out=$zipout\n");
	skip( "test zip doesn't work", 1 ) if $testZipDoesntWork;
	is( $status, 0 );
}

#--------- extract it by name
$status = $zip->extractMember($memberName, $newName);
is($status, AZ_OK);
ok(-f $newName);
is(fileCRC($newName), TESTSTRINGCRC);

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
is($members[2], $member);

# memberNames	# Archive::Zip::Archive
my @memberNames = $zip->memberNames();
is(scalar(@memberNames), 3);
is($memberNames[2], $memberName);

# memberNamed	# Archive::Zip::Archive
is($zip->memberNamed($memberName), $member);

# membersMatching	# Archive::Zip::Archive
@members = $zip->membersMatching('file');
is(scalar(@members), 1);
is($members[0], $member);

@members = $zip->membersMatching('.txt$');
is(scalar(@members), 2);
is($members[1], $member);

#--------- remove the string member and test the file
# removeMember	# Archive::Zip::Archive
$member = $zip->removeMember($members[0]);
is($member, $members[0]);

$status = $zip->writeToFileNamed( OUTPUTZIP );
is($status, AZ_OK);

SKIP: {
	skip( "No 'unzip' program to test against", 1 ) unless HAVEUNZIP;
	($status, $zipout) = testZip();
	# STDERR->print("status= $status, out=$zipout\n");
	skip( "test zip doesn't work", 1 ) if $testZipDoesntWork;
	is( $status, 0 );
}

#--------- add the string member at the end and test the file
# addMember	# Archive::Zip::Archive
$zip->addMember($member);
@members = $zip->members();

is(scalar(@members), 3);
is($members[2], $member);

# memberNames	# Archive::Zip::Archive
@memberNames = $zip->memberNames();
is(scalar(@memberNames), 3);
is($memberNames[1], $memberName);

$status = $zip->writeToFileNamed( OUTPUTZIP );
is($status, AZ_OK);

SKIP: {
	skip( "No 'unzip' program to test against", 1 ) unless HAVEUNZIP;
	($status, $zipout) = testZip();
	# STDERR->print("status= $status, out=$zipout\n");
	skip( "test zip doesn't work", 1 ) if $testZipDoesntWork;
	is( $status, 0 );
}

#--------- remove the file member
$member = $zip->removeMember($members[1]);
is($member, $members[1]);
is($zip->numberOfMembers(), 2);

#--------- replace the string member with the file member
# replaceMember	# Archive::Zip::Archive
$member = $zip->replaceMember($members[2], $member);
is($member, $members[2]);
is($zip->numberOfMembers(), 2);

#--------- re-add the string member
$zip->addMember($member);
is($zip->numberOfMembers(), 3);

@members = $zip->members();
$status = $zip->writeToFileNamed( OUTPUTZIP );
is($status, AZ_OK);

SKIP: {
	skip( "No 'unzip' program to test against", 1 ) unless HAVEUNZIP;
	($status, $zipout) = testZip();
	# STDERR->print("status= $status, out=$zipout\n");
	skip( "test zip doesn't work", 1 ) if $testZipDoesntWork;
	is( $status, 0 );
}

#--------- add compressed file
$member = $zip->addFile(File::Spec->catfile(TESTDIR, 'file.txt'));
ok(defined($member));
$member->desiredCompressionMethod(COMPRESSION_DEFLATED);
$member->fileName(TESTDIR . '/fileC.txt');

#--------- add uncompressed string
$member = $zip->addString(TESTSTRING, TESTDIR . '/stringU.txt');
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

@members = $zip->members();
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
$status = $zip->writeToFileNamed( INPUTZIP );
is($status, AZ_OK);

SKIP: {
	skip( "No 'unzip' program to test against", 1 ) unless HAVEUNZIP;
	($status, $zipout) = testZip(INPUTZIP);
	# STDERR->print("status= $status, out=$zipout\n");
	skip( "test zip doesn't work", 1 ) if $testZipDoesntWork;
	is( $status, 0 );
}

#--------- read from INPUTZIP (appending its entries)
# read	# Archive::Zip::Archive
$status = $zip->read(INPUTZIP);
is($status, AZ_OK);
is($zip->numberOfMembers(), 10);

#--------- clean up duplicate names
@members = $zip->members();
$member = $zip->removeMember($members[5]);
is($member->fileName(), TESTDIR . '/');

SCOPE: {
	for my $i (6..9)
	{
		$memberName = $members[$i]->fileName();
		$memberName =~ s/\.txt/2.txt/;
		$members[$i]->fileName($memberName);
	}
}
is(scalar($zip->membersMatching('2.txt')), 4);

#--------- write zip out and test it.
$status = $zip->writeToFileNamed( OUTPUTZIP );
is($status, AZ_OK);

SKIP: {
	skip( "No 'unzip' program to test against", 1 ) unless HAVEUNZIP;
	($status, $zipout) = testZip();
	# STDERR->print("status= $status, out=$zipout\n");
	skip( "test zip doesn't work", 1 ) if $testZipDoesntWork;
	is( $status, 0 );
}

#--------- Make sure that we haven't renamed files (this happened!)
is(scalar($zip->membersMatching('2\.txt$')), 4);

#--------- Now try extracting everyone
@members = $zip->members();
is($zip->extractMember($members[0]), AZ_OK);	#DM
is($zip->extractMember($members[1]), AZ_OK);	#NFM
is($zip->extractMember($members[2]), AZ_OK);
is($zip->extractMember($members[3]), AZ_OK);	#NFM
is($zip->extractMember($members[4]), AZ_OK);
is($zip->extractMember($members[5]), AZ_OK);
is($zip->extractMember($members[6]), AZ_OK);
is($zip->extractMember($members[7]), AZ_OK);
is($zip->extractMember($members[8]), AZ_OK);

#--------- count dirs
{
	my @dirs = grep { $_->isDirectory() } @members;
	is(scalar(@dirs), 1); 
	is($dirs[0], $members[0]);
}

#--------- count binary and text files
{
	my @binaryFiles = grep { $_->isBinaryFile() } @members;
	my @textFiles = grep { $_->isTextFile() } @members;
	is(scalar(@binaryFiles), 5); 
	is(scalar(@textFiles), 4); 
}

#--------- Try writing zip file to file handle
{
	my $fh;
	if ($catWorks)
	{
		unlink( OUTPUTZIP );
		$fh = FileHandle->new( CATPIPE . OUTPUTZIP );
		binmode($fh);
	}
	SKIP: {
		skip('cat does not work on this platform', 1) unless $catWorks;
		ok( $fh );
	}
#	$status = $zip->writeToFileHandle($fh, 0) if ($catWorks);
	$status = $zip->writeToFileHandle($fh) if ($catWorks);
	SKIP: {
		skip('cat does not work on this platform', 1) unless $catWorks;
		is( $status, AZ_OK );
	}
	$fh->close() if ($catWorks);
	SKIP: {
		skip( "No 'unzip' program to test against", 1 ) unless HAVEUNZIP;
		($status, $zipout) = testZip();
		is($status, 0);
	}
}

#--------- Change the contents of a string member
is(ref($members[2]), 'Archive::Zip::StringMember');
$members[2]->contents( "This is my new contents\n" );

#--------- write zip out and test it.
$status = $zip->writeToFileNamed( OUTPUTZIP );
is($status, AZ_OK);

SKIP: {
	skip( "No 'unzip' program to test against", 1 ) unless HAVEUNZIP;
	($status, $zipout) = testZip();
	# STDERR->print("status= $status, out=$zipout\n");
	skip( "test zip doesn't work", 1 ) if $testZipDoesntWork;
	is( $status, 0 );
}

#--------- Change the contents of a file member
is(ref($members[1]), 'Archive::Zip::NewFileMember');
$members[1]->contents( "This is my new contents\n" );

#--------- write zip out and test it.
$status = $zip->writeToFileNamed( OUTPUTZIP );
is($status, AZ_OK);

SKIP: {
	skip( "No 'unzip' program to test against", 1 ) unless HAVEUNZIP;
	($status, $zipout) = testZip();
	# STDERR->print("status= $status, out=$zipout\n");
	skip( "test zip doesn't work", 1 ) if $testZipDoesntWork;
	is( $status, 0 );
}

#--------- Change the contents of a zip member

is(ref($members[7]), 'Archive::Zip::ZipFileMember');
$members[7]->contents( "This is my new contents\n" );

#--------- write zip out and test it.
$status = $zip->writeToFileNamed( OUTPUTZIP );
is($status, AZ_OK);

SKIP: {
	skip( "No 'unzip' program to test against", 1 ) unless HAVEUNZIP;
	($status, $zipout) = testZip();
	# STDERR->print("status= $status, out=$zipout\n");
	skip( "test zip doesn't work", 1 ) if $testZipDoesntWork;
	is( $status, 0 );
}


#--------- now clean up
# END { system("rm -rf " . TESTDIR . " " . OUTPUTZIP . " " . INPUTZIP) }

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
# sub extraField	# Archive::Zip::Member
# sub isEncrypted	# Archive::Zip::Member
# sub isTextFile	# Archive::Zip::Member
# sub isBinaryFile	# Archive::Zip::Member
# sub isDirectory	# Archive::Zip::Member
# sub lastModTime	# Archive::Zip::Member
# sub _writeDataDescriptor	# Archive::Zip::Member
# sub isDirectory	# Archive::Zip::DirectoryMember
# sub _becomeDirectory	# Archive::Zip::DirectoryMember
# sub diskNumberStart	# Archive::Zip::ZipFileMember
