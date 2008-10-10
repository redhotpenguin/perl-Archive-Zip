#!/usr/bin/perl

use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}

use Test::More tests => 6;
use File::Spec       ();
use File::Spec::Unix ();
use Archive::Zip     qw( :ERROR_CODES );

my $expected_fn = File::Spec->catfile(
    File::Spec->curdir, "t", "badjpeg", "expected.jpg"
);
my $expected_zip = File::Spec::Unix->catfile(
    File::Spec::Unix->curdir, "t", "badjpeg", "expected.jpg",
);

my $got_fn = "got.jpg";
my $archive_fn = "out.zip";
my ( $before, $after );
sub slurp_file {
	my $filename = shift;
	open ( my $fh, '<', $filename)
	or die 'Can not open file';
	my $contents;
	binmode( $fh );
	SCOPE: {
		local $/;
		$contents = <$fh>;
	}
	close $fh;
	return $contents;
}

sub binary_is {
    my ($got, $expected, $msg) = @_;
    local $Test::Builder::Level = $Test::Builder::Level+1;
    my $verdict = ($got eq $expected);
    ok ($verdict, $msg);
    if (!$verdict) {
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
        for my $byte_idx (0 .. ($len-1)) {
            my $got_byte      = substr($got, $byte_idx, 1);
            my $expected_byte = substr($expected, $byte_idx, 1);
            if ($got_byte ne $expected_byte) {
                diag(
                    sprintf(
                        "Byte %i differ: got == 0x%.2x, expected == 0x%.2x",
                        $byte_idx, ord($got_byte), ord($expected_byte)
                    )
                );
                last BYTE_LOOP;
            }
        }
    }
}

sub run_tests {
    my $id = shift;
    my $msg_it = sub {
        my $msg_raw = shift;
        return "$id - $msg_raw";
    };

    # Read the contents of the good file into the variable.
    $before = slurp_file($expected_fn);

    # Zip the file.
    SCOPE: {
        my $zip = Archive::Zip->new();
        $zip->addFile( $expected_fn );
        $zip->extractMember( $expected_zip, $got_fn );
        $after = slurp_file($got_fn);
        
        unlink $got_fn;

        # TEST:$n=$n+1 
        binary_is(
            $after, $before,
            $msg_it->("Content of file after extraction"),
        );

        my $status = $zip->writeToFileNamed( $archive_fn );
        # TEST:$n=$n+1
        cmp_ok( $status, '==', AZ_OK, $msg_it->('Zip was written fine') );
    }

    # Read back the file from the archive.
    SCOPE: {
        my $zip2;
        $zip2 = Archive::Zip->new( $archive_fn );

        $zip2->extractMember( $expected_zip, $got_fn );

        $after = slurp_file( $got_fn );

        unlink $got_fn;
        unlink $archive_fn;

        # TEST:$n=$n+1
        binary_is(
            $after, $before,
            $msg_it->('Read back the file from the archive'),
        );
    }    
}

# Run the tests once with $\ undef.
run_tests("Normal");

# Run them once while setting $\.
SCOPE: {
    local $\ = "\n";
    run_tests(q{$\ is \n});
}
