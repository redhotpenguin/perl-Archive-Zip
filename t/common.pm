package common;

# See https://github.com/redhotpenguin/perl-Archive-Zip/blob/master/t/README.md
# for a short documentation on the Archive::Zip test infrastructure.

use strict;
use warnings;

use Carp qw(croak longmess);
use Config;
use File::Spec;
use File::Spec::Unix;
use File::Temp qw(tempfile tempdir);
use Test::More;

use Archive::Zip qw(:ERROR_CODES);

use Exporter qw(import);

@common::EXPORT = qw(TESTDIR INPUTZIP OUTPUTZIP
                     TESTSTRING TESTSTRINGLENGTH TESTSTRINGCRC
                     PATH_REL PATH_ABS PATH_ZIPFILE PATH_ZIPDIR PATH_ZIPABS
                     passThrough readFile execProc execPerl dataPath testPath
                     azbinis azok azis
                     azopen azuztok azwok);

### Constants

# Flag whether we run in an automated test environment
use constant _IN_AUTOTEST_ENVIRONMENT =>
    exists($ENV{'AUTOMATED_TESTING'}) ||
    exists($ENV{'NONINTERACTIVE_TESTING'}) ||
    exists($ENV{'PERL_CPAN_REPORTER_CONFIG'});

use constant TESTDIR => do {
    -d 'testdir' or mkdir 'testdir' or die $!;
    tempdir(DIR => 'testdir', CLEANUP => 1, EXLOCK => 0);
};

use constant INPUTZIP =>
    (tempfile('testin-XXXXX', SUFFIX => '.zip', TMPDIR => 1, $^O eq 'MSWin32' ? () : (UNLINK => 1)))[1];

use constant OUTPUTZIP =>
    (tempfile('testout-XXXXX', SUFFIX => '.zip', TMPDIR => 1, $^O eq 'MSWin32' ? () : (UNLINK => 1)))[1];

# 300-character test string.  CRC-32 should be ac373f32.
use constant TESTSTRING       => join("\n", 1 .. 102) . "\n";
use constant TESTSTRINGLENGTH => length(TESTSTRING);
use constant TESTSTRINGCRC    => Archive::Zip::computeCRC32(TESTSTRING);

# Path types used by functions dataPath and testPath
use constant PATH_REL     => \ "PATH_REL";
use constant PATH_ABS     => \ "PATH_ABS";
use constant PATH_ZIPFILE => \ "PATH_ZIPFILE";
use constant PATH_ZIPDIR  => \ "PATH_ZIPDIR";
use constant PATH_ZIPABS  => \ "PATH_ZIPABS";

### Auxilliary Functions

sub passThrough
{
    my $fromFile = shift;
    my $toFile   = shift;
    my $action   = shift;

    my $zip = Archive::Zip->new();
    $zip->read($fromFile) == AZ_OK or
        croak "Cannot read archive from \"$fromFile\"";
    if ($action)
    {
        for my $member($zip->members())
        {
            &$action($member) ;
        }
    }
    $zip->writeToFileNamed($toFile) == AZ_OK or
        croak "Cannot write archive to \"$toFile\"";
}

sub readFile
{
    my $file = shift;
    open(F, "<$file") or
        croak "Cannot open file \"$file\" ($!)";
    binmode(F);
    local $/;
    my $data = <F>;
    defined($data) or
        croak "Cannot read file \"$file\" ($!)";
    close(F);
    return $data;
}

sub execProc
{
    # "2>&1" DOES run portably at least on DOSish and on MACish
    # operating systems
    return (scalar(`$_[0] 2>&1`), $?);
}

sub execPerl
{
    my $libs = join('" -I"', @INC);
    my $perl = $Config{'perlpath'};
    return execProc("\"$perl\" \"-I$libs\" -w \"" . join('" "', @_) . "\"");
}

my ($cwdVol, $cwdPath) = File::Spec->splitpath(File::Spec->rel2abs('.'), 1);
my @cwdDirs            = File::Spec->splitdir($cwdPath);

my @dataDirs = ('t', 'data');

sub dataPath
{
    my $dataFile = shift;
    my $pathType = @_ ? shift : PATH_REL;
    # avoid another dependency on File::Basename
    (undef, undef, $dataFile) = File::Spec->splitpath($dataFile);
    $dataFile .= ".zip" unless $dataFile =~ /\.[a-z0-9]+$/i;
    if ($pathType == PATH_REL) {
        return File::Spec->catfile(@dataDirs, $dataFile);
    }
    elsif ($pathType == PATH_ABS) {
        return File::Spec->catpath($cwdVol, File::Spec->catdir(@cwdDirs, @dataDirs), $dataFile);
    }
    elsif ($pathType == PATH_ZIPFILE) {
        return File::Spec::Unix->catfile(@dataDirs, $dataFile);
    }
    elsif ($pathType == PATH_ZIPDIR) {
        return File::Spec::Unix->catfile(@dataDirs, $dataFile) . "/";
    }
    else {
        return File::Spec::Unix->catfile(@cwdDirs, @dataDirs, $dataFile);
    }
}

my @testDirs = File::Spec->splitdir(TESTDIR);

# This function uses File::Spec->catfile and File::Spec->catpath
# to assemble paths.  Both methods expect the last item in a path
# to be a file, which is not necessarily always the case for this
# function.  Since the current approach works fine and any other
# approach would be too complex to implement, let's keep things
# as is.
sub testPath
{
    my @pathItems = @_;
    my $pathType  = ref($pathItems[-1]) ? pop(@pathItems) : PATH_REL;
    if ($pathType == PATH_REL) {
        return File::Spec->catfile(@testDirs, @pathItems);
    }
    elsif ($pathType == PATH_ABS) {
        # go to some contortions to have a non-empty "file" to
        # present to File::Spec->catpath
        if (@pathItems) {
            my $file = pop(@pathItems);
            return File::Spec->catpath($cwdVol, File::Spec->catdir(@cwdDirs, @testDirs, @pathItems), $file);
        }
        else {
            my $file = pop(@testDirs);
            return File::Spec->catpath($cwdVol, File::Spec->catdir(@cwdDirs, @testDirs), $file);
        }
    }
    elsif ($pathType == PATH_ZIPFILE) {
        return File::Spec::Unix->catfile(@testDirs, @pathItems);
    }
    elsif ($pathType == PATH_ZIPDIR) {
        return File::Spec::Unix->catfile(@testDirs, @pathItems) . "/";
    }
    else {
        return File::Spec::Unix->catfile(@cwdDirs, @testDirs, @pathItems);
    }
}

### Initialization

# Test whether "unzip -t" is available, which we consider to be
# the case if we successfully can run "unzip -t" on
# "t/data/simple.zip".  Keep this intentionally simple and let
# the operating system do all the path search stuff.
#
# The test file "t/data/simple.zip" has been generated from
# "t/data/store.zip" with the following alterations: All "version
# made by" and "version needed to extract" fields have been set
# to "0x00a0", which should guarantee maximum compatibility
# according to APPNOTE.TXT.
my $uztCommand = 'unzip -t';
my $uztOutErr = "";
my $uztExitVal = undef;
my $uztWorks = eval {
    my $simplezip = dataPath("simple.zip");
    ($uztOutErr, $uztExitVal) = execProc("$uztCommand $simplezip");
    return $uztExitVal == 0;
};
if (! defined($uztWorks)) {
    $uztWorks = 0;
    $uztOutErr .= "Caught exception $@";
}
elsif (! $uztWorks) {
    $uztOutErr .= "Exit value $uztExitVal\n";
}

# Check whether we can write through a (non-seekable) pipe
my $pipeCommand = '| "' . $Config{'perlpath'} . '" -pe "BEGIN{binmode(STDIN);binmode(STDOUT)}" >';
my $pipeError = "";
my $pipeWorks = eval {
    my $testString = pack('C256', 0 .. 255);
    my $fh = FileHandle->new("$pipeCommand " . OUTPUTZIP) or die $!;
    binmode($fh) or die $!;
    $fh->write($testString, length($testString)) or die $!;
    $fh->close() or die $!;
    (-f OUTPUTZIP) or die $!;
    (-s OUTPUTZIP) == length($testString) or die "length mismatch";
    readFile(OUTPUTZIP) eq $testString  or die "data mismatch";
    return 1;
} or $pipeError = $@;

### Test Functions

# Diags or notes, depending on whether we run in an automated
# test environment or not.
sub _don
{
    if (_IN_AUTOTEST_ENVIRONMENT) {
        diag(@_);
    }
    else {
        note(@_);
    }
}

sub azbinis
{
    my ($got, $expected, $name) = @_;
    local $Test::Builder::Level = $Test::Builder::Level + 1;
    my $ok = is($got, $expected, $name);
    if (!$ok) {
        my $len;
        if (length($got) > length($expected)) {
            $len = length($expected);
            diag("got is longer than expected");
        } elsif (length($got) < length($expected)) {
            $len = length($got);
            diag("expected is longer than got");
        } else {
            $len = length($got);
        }

      BYTE_LOOP:
        for my $byte_idx (0 .. ($len - 1)) {
            my $got_byte      = substr($got,      $byte_idx, 1);
            my $expected_byte = substr($expected, $byte_idx, 1);
            if ($got_byte ne $expected_byte) {
                diag(sprintf("byte %i differs: got == 0x%.2x, expected == 0x%.2x",
                             $byte_idx, ord($got_byte), ord($expected_byte)));
                last BYTE_LOOP;
            }
        }
    }
}

my @errors = ();
my $trace  = undef;

$Archive::Zip::ErrorHandler = sub {
    push(@errors, @_);
    $trace = longmess();
};

sub azok
{
    my $status = shift;
    my $name   = @_ ? shift : undef;

    local $Test::Builder::Level = $Test::Builder::Level + 1;

    return azis($status, AZ_OK, $name);
}

sub azis
{
    my $status = shift;
    my $xpst   = (@_ && $_[0] =~ /^\d+$/) ? shift : undef;
    my $emre   = (@_ && ref($_[0]) eq "Regexp") ? shift : undef;
    my $name   = @_ ? shift : undef;

    local $Test::Builder::Level = $Test::Builder::Level + 1;

    my $errors = join("\n", map { defined($_) ? $_ : "" } @errors);

    my $ok = ok(# ensure sane status
                (defined($status))                     &&
                # ensure sane expected status
                (defined($xpst) || defined($emre))     &&
                # ensure sane errors
                ($status != AZ_OK || @errors == 0)     &&
                ($status == AZ_OK || @errors != 0)     &&
                # finally, test specified conditions
                (! defined($xpst) || $status == $xpst) &&
                (! defined($emre) || $errors =~ /$emre/), $name);


    if (! $ok) {
        $status = "undefined" unless defined($status);
        diag("  got status: $status");
        diag("    expected: $xpst") if defined($xpst);
        if (@errors) {
        $errors =~ s/^\s+//;
        $errors =~ s/\s+$//;
        $errors =~ s/\n/\n              /g;
        diag("  got errors: $errors");
        }
        else {
        diag("  got errors: none");
        }
        diag("    expected: $emre") if defined($emre);
        diag($trace)                if defined($trace);
    }
    elsif ($status != AZ_OK) {
        # do not use "diag" or "_don" here, as it messes up test
        # output beyond any readability
        note("Got (expected) status != AZ_OK");
        note("  got status: $status");
        note("    expected: $xpst") if defined($xpst);
        if (@errors) {
        $errors =~ s/^\s+//;
        $errors =~ s/\s+$//;
        $errors =~ s/\n/\n              /g;
        note("  got errors: $errors");
        }
        else {
        note("  got errors: none");
        }
        note("    expected: $emre") if defined($emre);
        note($trace)                if defined($trace);
    }

    @errors = ();
    $trace  = undef;

    return $ok;
}

sub azopen
{
    my $file = @_ ? shift : OUTPUTZIP;

    if ($pipeWorks) {
        if (-f $file && ! unlink($file)) {
            return undef;
        }
        return FileHandle->new("$pipeCommand $file");
    }
    else {
        return FileHandle->new("> $file");
    }
}

my %rzipCache = ();

sub azuztok
{
    my $file   = @_ & 1  ? shift : undef;
    my %params = @_;
       $file   = exists($params{'file'}) ? $params{'file'} :
                 defined($file) ? $file : OUTPUTZIP;
    my $refzip = $params{'refzip'};
    my $xppats = $params{'xppats'};
    my $name   = $params{'name'};

    local $Test::Builder::Level = $Test::Builder::Level + 1;

    if (! $uztWorks) {
      SKIP: {
          skip("\"unzip -t\" not available", 1)
        }
        return 1;
    }

    my $rOutErr;
    my $rExitVal;
    if (defined($refzip)) {
        # normalize reference zip file name to its base name
        (undef, undef, $refzip) = File::Spec->splitpath($refzip);
        $refzip .= ".zip" unless $refzip =~ /\.zip$/i;

        if (! exists($rzipCache{$refzip})) {
            my $rFile = dataPath($refzip);
            ($rOutErr, $rExitVal) = execProc("$uztCommand $rFile");
            $rzipCache{$refzip} = [$rOutErr, $rExitVal];
            if ($rExitVal != 0) {
                _don("Non-zero exit value on reference");
                _don("\"unzip -t\" returned non-zero exit value $rExitVal on file \"$rFile\"");
                _don("(which might be entirely OK on your operating system) and resulted in the");
                _don("following output:");
                _don($rOutErr);
            }
        }
        else {
            ($rOutErr, $rExitVal) = @{$rzipCache{$refzip}};
        }
    }

    my ($outErr, $exitVal) = execProc("$uztCommand $file");
    if (defined($refzip)) {
        my $ok = ok($exitVal == $rExitVal, $name);
        if (! $ok) {
            diag("Got result:");
            diag($outErr . "Exit value $exitVal\n");
            diag("Expected (more or less) result:");
            diag($rOutErr . "Exit value $rExitVal\n");
        }
        elsif ($exitVal) {
            _don("Non-zero exit value");
            _don("\"unzip -t\" returned non-zero exit value $exitVal on file \"$file\"");
            _don("(which might be entirely OK on your operating system) and resulted in the");
            _don("following output:");
            _don($outErr);
        }
        return $ok;
    }
    elsif (defined($xppats)) {
        my $ok = 0;
        for my $xppat (@$xppats) {
            my ($xpExitVal, $outErrRE, $osName) = @$xppat;
            if ((! defined($xpExitVal) || $exitVal == $xpExitVal) &&
                (! defined($outErrRE)  || $outErr =~ /$outErrRE/) &&
                (! defined($osName)    || $osName eq $^O)) {
                $ok = 1;
                last;
            }
        }
        $ok = ok($ok, $name);
        if (! $ok) {
            diag("Got result:");
            diag($outErr . "Exit value $exitVal\n");
        }
        elsif ($exitVal) {
            _don("Non-zero exit value");
            _don("\"unzip -t\" returned non-zero exit value $exitVal on file \"$file\"");
            _don("(which might be entirely OK on your operating system) and resulted in the");
            _don("following output:");
            _don($outErr);
        }
        return $ok;
    }
    else {
        my $ok = ok($exitVal == 0, $name);
        if (! $ok) {
            diag("Got result:");
            diag($outErr . "Exit value $exitVal\n");
        }
        return $ok;
    }
}

sub azwok
{
    my $zip    = shift;
    my %params = @_;
    my $file   = exists($params{'file'}) ? $params{'file'} : OUTPUTZIP;
    my $name   = $params{'name'} ? $params{'name'} : "write and test zip file";

    local $Test::Builder::Level = $Test::Builder::Level + 1;

    my $ok;

    my $fh;
    $ok = 1;
    $ok &&= ok($fh = azopen($file), "$name - open piped handle");
    $ok &&= azok($zip->writeToFileHandle($fh), "$name - write piped");
    $ok &&= ok($fh->close(), "$name - close piped handle");
    if ($ok) {
        azuztok($file, %params, 'name' => "$name - test write piped");
    }
    else {
      SKIP: {
          skip("$name - previous piped write failed", 1);
        }
    }

    $ok = 1;
    $ok &&= azok($zip->writeToFileNamed($file), "$name - write plain");
    if ($ok) {
        azuztok($file, %params, 'name' => "$name - test write plain");
    }
    else {
      SKIP: {
          skip("$name - previous plain write failed", 1);
        }
    }
}

### One-Time Diagnostic Functions

# These functions write diagnostic information that does not
# differ per test prorgram execution and should be called only
# once, hence, in 01_init.t.

# Write version information on "unzip", if available.
sub azuzdiag
{
    my ($outErr, $exitVal) = execProc('unzip');
    _don("Calling \"unzip\" resulted in:");
    _don($outErr . "Exit value $exitVal\n");
}

# Write some diagnostics if "unzip -t" is not available.
sub azuztdiag
{
    unless ($uztWorks) {
        diag("Skipping tests on zip files with \"$uztCommand\".");
        _don("Calling \"$uztCommand\" failed:");
        _don($uztOutErr);
        _don("Some features are not tested.");
    }
}

# Write some diagnostics if writing through pipes is not
# available.
sub azwpdiag
{
    unless ($pipeWorks) {
        diag("Skipping write tests through pipes.");
        _don("Writing through pipe failed:");
        _don($pipeError);
        _don("Some features are not tested.");
    }
}

1;
