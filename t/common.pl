# Shared defs for test programs

# Paths. Must make case-insensitive.
use constant TESTDIR   => 'testdir';
use constant INPUTZIP  => 'testin.zip';
use constant OUTPUTZIP => 'testout.zip';

# Do we have the 'zip' and 'unzip' programs?
# Embed a copy of the module, rather than adding a dependency
SCOPE: {
	package File::Which;

	use File::Spec;

	my $Is_VMS    = ($^O eq 'VMS');
	my $Is_MacOS  = ($^O eq 'MacOS');
	my $Is_DOSish = (($^O eq 'MSWin32') or
                	($^O eq 'dos')     or
                	($^O eq 'os2'));

	# For Win32 systems, stores the extensions used for
	# executable files
	# For others, the empty string is used
	# because 'perl' . '' eq 'perl' => easier
	my @path_ext = ('');
	if ($Is_DOSish) {
    	if ($ENV{PATHEXT} and $Is_DOSish) {    # WinNT. PATHEXT might be set on Cygwin, but not used.
	        push @path_ext, split ';', $ENV{PATHEXT};
    	}
    	else {
	        push @path_ext, qw(.com .exe .bat); # Win9X or other: doesn't have PATHEXT, so needs hardcoded.
    	}
	}
	elsif ($Is_VMS) { 
    	push @path_ext, qw(.exe .com);
	}

	sub which {
    	my ($exec) = @_;

    	return undef unless $exec;

    	my $all = wantarray;
    	my @results = ();
    
	    # check for aliases first
	    if ($Is_VMS) {
	        my $symbol = `SHOW SYMBOL $exec`;
	        chomp($symbol);
	        if (!$?) {
	            return $symbol unless $all;
	            push @results, $symbol;
	        }
	    }
	    if ($Is_MacOS) {
	        my @aliases = split /\,/, $ENV{Aliases};
	        foreach my $alias (@aliases) {
	            # This has not been tested!!
	            # PPT which says MPW-Perl cannot resolve `Alias $alias`,
	            # let's just hope it's fixed
	            if (lc($alias) eq lc($exec)) {
	                chomp(my $file = `Alias $alias`);
	                last unless $file;  # if it failed, just go on the normal way
	                return $file unless $all;
	                push @results, $file;
	                # we can stop this loop as if it finds more aliases matching,
	                # it'll just be the same result anyway
	                last;
	            }
	        }
	    }
	
	    my @path = File::Spec->path();
	    unshift @path, File::Spec->curdir if $Is_DOSish or $Is_VMS or $Is_MacOS;
	
	    for my $base (map { File::Spec->catfile($_, $exec) } @path) {
	       for my $ext (@path_ext) {
	            my $file = $base.$ext;
	# print STDERR "$file\n";
	
	            if ((-x $file or    # executable, normal case
	                 ($Is_MacOS ||  # MacOS doesn't mark as executable so we check -e
	                  ($Is_DOSish and grep { $file =~ /$_$/i } @path_ext[1..$#path_ext])
	                                # DOSish systems don't pass -x on non-exe/bat/com files.
	                                # so we check -e. However, we don't want to pass -e on files
	                                # that aren't in PATHEXT, like README.
	                 and -e _)
	                ) and !-d _)
	            {                   # and finally, we don't want dirs to pass (as they are -x)
	
	# print STDERR "-x: ", -x $file, " -e: ", -e _, " -d: ", -d _, "\n";
	
	                    return $file unless $all;
	                    push @results, $file;       # Make list to return later
	            }
	        }
	    }
	    
	    if($all) {
	        return @results;
	    } else {
	        return undef;
	    }
	}
}
use constant HAVEZIP   => !! File::Which::which('zip');
use constant HAVEUNZIP => !! File::Which::which('unzip');

use constant ZIP     => 'zip ';
use constant ZIPTEST => 'unzip -t ';

# 300-character test string
use constant TESTSTRING       => join ( "\n", 1 .. 102 ) . "\n";
use constant TESTSTRINGLENGTH => length(TESTSTRING);

# CRC-32 should be ac373f32
use constant TESTSTRINGCRC => Archive::Zip::computeCRC32(TESTSTRING);

# This is so that it will work on other systems.
use constant CAT     => $^X . ' -pe "BEGIN{binmode(STDIN);binmode(STDOUT)}"';
use constant CATPIPE => '| ' . CAT . ' >';

use vars qw($zipWorks $testZipDoesntWork $catWorks);
local ( $zipWorks, $testZipDoesntWork, $catWorks );

# Run ZIPTEST to test a zip file.
sub testZip {
	my $zipName = shift || OUTPUTZIP;
	if ( $testZipDoesntWork ) {
		return wantarray ? ( 0, '' ) : 0;
	}
	my $cmd = ZIPTEST . $zipName . ( $^O eq 'MSWin32' ? '' : ' 2>&1' );
	my $zipout = `$cmd`;
	return wantarray ? ( $?, $zipout ) : $?;
}

# Return the crc-32 of the given file (0 if empty or error)
sub fileCRC {
	my $fileName = shift;
	local $/ = undef;
	my $fh = IO::File->new( $fileName, "r" );
	binmode($fh);
	return 0 if not defined($fh);
	my $contents = <$fh>;
	return Archive::Zip::computeCRC32($contents);
}

#--------- check to see if cat works

sub testCat {
	my $fh = IO::File->new( CATPIPE . OUTPUTZIP );
	binmode($fh);
	my $testString = pack( 'C256', 0 .. 255 );
	my $testCrc    = Archive::Zip::computeCRC32($testString);
	$fh->write( $testString, length($testString) ) or return 0;
	$fh->close();
	( -f OUTPUTZIP ) or return 0;
	my @stat = stat(OUTPUTZIP);
	$stat[7] == length($testString) or return 0;
	fileCRC(OUTPUTZIP) == $testCrc or return 0;
	unlink(OUTPUTZIP);
	return 1;
}

BEGIN {
	$catWorks = testCat();
	unless ( $catWorks ) {
		warn( 'warning: ', CAT, " doesn't seem to work, may skip some tests" );
	}
}

#--------- check to see if zip works (and make INPUTZIP)

BEGIN {
	unlink(INPUTZIP);

	# Do we have zip installed?
	if ( HAVEZIP ) {
		my $cmd    = ZIP . INPUTZIP . ' *' . ( $^O eq 'MSWin32' ? '' : ' 2>&1' );
		$zipout = `$cmd`;
		$zipWorks  = not $?;
		unless ( $zipWorks ) {
			warn( 'warning: ', ZIP, " doesn't seem to work, may skip some tests" );
		}
	}
}

#--------- check to see if unzip -t works

BEGIN {
	$testZipDoesntWork = 0;
	if ( HAVEUNZIP ) {
		my ( $status, $zipout ) = testZip(INPUTZIP);
		$testZipDoesntWork = $status;

		# Again, on Win32 no big surprise if this doesn't work
		if ( $testZipDoesntWork ) {
			warn( 'warning: ', ZIPTEST, " doesn't seem to work, may skip some tests" );
		}
	}
}

1;
