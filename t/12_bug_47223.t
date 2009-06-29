#!/use/bin/perl

# Check Windows Explorer compatible directories

use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}

use Test::More;
use Archive::Zip;
use File::Temp;
use File::Spec;

if ($^O eq 'MSWin32') {
	plan( tests => 1 );
} else {
	plan( skip_all => 'Only required on Win32.' );
}

my $dist   = Win32::GetShortPathName(File::Spec->rel2abs(File::Spec->catfile(qw(t data winzip.zip))));
my $tmpdirname = File::Spec->catdir(File::Spec->tmpdir, "parXXXXX");
my $tmpdir = File::Temp::mkdtemp($tmpdirname)        
      or die "Could not create temporary directory from template '$tmpdirname': $!";
my $path = $tmpdir;
$path = File::Spec->catdir($tmpdir, 'test');

my $zip = Archive::Zip->new();

$zip->read($dist);
ok(eval { $zip->extractTree('', "$path/"); 1; });
