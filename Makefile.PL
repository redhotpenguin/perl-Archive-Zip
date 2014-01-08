use strict;
BEGIN {
	require 5.004;
}

use Config;
use ExtUtils::MakeMaker;

WriteMakefile1(
	META_MERGE => {
		resources => {
			repository => 'https://github.com/redhotpenguin/perl-Archive-Zip-svn',
		},
	},
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
		'Time::Local'         => 0,
	},
	BUILD_REQUIRES => {
		'Test::More'          => '0.88',
	},
	clean => {
		FILES => join( ' ', qw{
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
	LICENSE => 'perl',
	MIN_PERL_VERSION => 5.006,
	BINARY_LOCATION => $Config{'archname'} . "/\$(DISTVNAME)-PPD.tar\$(SUFFIX)",
	AUTHOR          => 'Ned Konz <perl@bike-nomad.com>',
	ABSTRACT_FROM   => 'lib/Archive/Zip.pm',
);

sub WriteMakefile1 {  #Written by Alexandr Ciornii, version 0.21. Added by eumm-upgrade.
	my %params=@_;
	my $eumm_version=$ExtUtils::MakeMaker::VERSION;
	$eumm_version=eval $eumm_version;
	die "EXTRA_META is deprecated" if exists $params{EXTRA_META};
	die "License not specified" if not exists $params{LICENSE};
	if ($params{BUILD_REQUIRES} and $eumm_version < 6.5503) {
		#EUMM 6.5502 has problems with BUILD_REQUIRES
		$params{PREREQ_PM}={ %{$params{PREREQ_PM} || {}} , %{$params{BUILD_REQUIRES}} };
		delete $params{BUILD_REQUIRES};
	}
	delete $params{CONFIGURE_REQUIRES} if $eumm_version < 6.52;
	delete $params{MIN_PERL_VERSION} if $eumm_version < 6.48;
	delete $params{META_MERGE} if $eumm_version < 6.46;
	delete $params{META_ADD} if $eumm_version < 6.46;
	delete $params{LICENSE} if $eumm_version < 6.31;
	delete $params{AUTHOR} if $] < 5.005;
	delete $params{ABSTRACT_FROM} if $] < 5.005;
	delete $params{BINARY_LOCATION} if $] < 5.005;

	WriteMakefile(%params);
}

