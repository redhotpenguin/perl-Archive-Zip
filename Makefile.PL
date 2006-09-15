require 5.003_96;

use Config;
use ExtUtils::MakeMaker;

# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
sub MY::postamble {
	if ( $^O eq 'VMS' ) {
		return '';
	}

	return '

docs/Archive-Zip.pdf:  docs/Archive-Zip.ps
	ps2pdf $<

docs/Archive-Zip.ps:  docs/Archive-Zip.ssd
	tssd -toPS $<

.PHONY: pods

pods:
	otl2pod lib/Archive/Zip.otl > lib/Archive/Zip.pod
	otl2pod lib/Archive/Zip/FAQ.otl > lib/Archive/Zip/FAQ.pod
';
}

WriteMakefile(
	NAME          => 'Archive::Zip',
	VERSION_FROM  => 'lib/Archive/Zip.pm', # finds $VERSION
	($] < 5.005 ? () :
		(
			BINARY_LOCATION => $Config{'archname'} . "/\$(DISTVNAME)-PPD.tar\$(SUFFIX)",
			AUTHOR          => 'Ned Konz <perl@bike-nomad.com>',
			ABSTRACT_FROM   => 'lib/Archive/Zip.pod',
		)),
	PREREQ_PM => {
		'Compress::Zlib' => '1.14',
		'Carp'           => 0,
		'Data::Dumper'   => 0,      # examples/zipinfo.pl
		'File::Path'     => 0,
		'File::Find'     => 0,
		'File::Basename' => 0,
		'File::Spec'     => '0.80', # need splitpath()
		'File::Copy'     => 0,
		'File::Temp'     => 0,
		'File::Which'    => '0.05', # Should really be build_requires
		'Getopt::Std'    => 0,      # examples/extract.pl
		'IO::File'       => 0,
		'IO::Handle'     => 0,
		'IO::Seekable'   => 0,
		'Test::More'     => '0.42',
		'Time::Local'    => 0,
	},
	EXE_FILES => [ 'bin/crc32' ],
	clean => {
		FILES => 'test.log testDir/* testDir/ testin.zip testout.zip test2.zip'
	},
	dist => {
		COMPRESS => 'gzip',
		SUFFIX   => '.gz',
		ZIP      => 'zip',
		ZIPFLAGS => '-r'
	},
);
