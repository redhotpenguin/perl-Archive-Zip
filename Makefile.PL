use strict;
BEGIN {
	require 5.003_96;
}

use Config;
use ExtUtils::MakeMaker;

WriteMakefile(
	NAME          => 'Archive::Zip',
	VERSION_FROM  => 'lib/Archive/Zip.pm',
	EXE_FILES     => [ 'script/crc32' ],
	PREREQ_PM     => {
		'Compress::Raw::Zlib' => '2.017',
		# 'Data::Dumper'      => 0,      # examples/zipinfo.pl
		'File::Path'          => 0,
		'File::Find'          => 0,
		'File::Basename'      => 0,
		'File::Spec'          => '0.80',   # need splitpath()
		'File::Copy'          => 0,
		'File::Temp'          => 0,
		# 'File::Which'       => '0.05', # Embedded in common.pl
		# 'Getopt::Std'       => 0,      # examples/extract.pl
		'IO::File'            => 0,
		'IO::Handle'          => 0,
		'IO::Seekable'        => 0,
		'Test::More'          => '0.42',
		'Time::Local'         => 0,
	},
	clean => {
		FILES => join( '', qw{
			test.log
			testdir/*
			testdir/
			extracted/testdir/*
			extracted/testdir
			extracted/
			testin.zip
			testout.zip
			test2.zip
		} ),
	},
	dist => {
		COMPRESS => 'gzip',
		SUFFIX   => '.gz',
		ZIP      => 'zip',
		ZIPFLAGS => '-r'
	},
	( $ExtUtils::MakeMaker::VERSION ge '6.31' ? (
		LICENSE => 'perl',
	) : () ),
	($ExtUtils::MakeMaker::VERSION ge '6.48' ? (
		'MIN_PERL_VERSION' => 5.003_96,
	) : ()),
	( $] >= 5.005 ? (
		BINARY_LOCATION => $Config{'archname'} . "/\$(DISTVNAME)-PPD.tar\$(SUFFIX)",
		AUTHOR          => 'Ned Konz <perl@bike-nomad.com>',
                ABSTRACT_FROM   => 'lib/Archive/Zip.pm',
	) : () ),
);
