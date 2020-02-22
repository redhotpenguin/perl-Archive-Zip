# Archive-Zip Tests

This document provides some information on writing tests for the
Archive::Zip module.  Note that the tests have been evolving
rather organically over a long time and may contain old-fashioned
Perl.


## General Guidelines

-   To keep test headers somewhat uniform, use a header along the
    following lines:

    ```perl
    #!/usr/bin/perl

    # See https://github.com/redhotpenguin/perl-Archive-Zip/blob/master/t/README.md
    # for a short documentation on the Archive::Zip test infrastructure.

    use strict;

    BEGIN { $^W = 1; }

    use Test::More;

    use Archive::Zip qw();

    use lib 't';
    use common;
    ```

-   Use `BEGIN { $^W = 1; }` in the test headers instead of the
    usually preferred `use warnings;` since that way the
    Archive::Zip module itself and its descendants get executed
    with warnings, too.  Which, unfortunately, otherwise would
    not be the case.

-   Keep test data below directory `t/data` without any
    additional subdirectories and access it by means of function
    `dataPath`.

-   Create temporary results only in directory `TESTDIR` and in
    files `INPUTZIP` and `OUTPUTZIP` to avoid race conditions
    when tests are executed in parallel.  Access directory
    `TESTDIR` and any paths below it by means of function
    `testPath`.


## Constants Provided by Package common

Package common, included by `use lib 't'; use common;` in a test
header, provides the following constants (which are all exported
by default):

-   `TESTDIR`

    Relative path to a unique (per test program) temporary test
    directory located below the build directory of this module.
    Better use function `testPath` to access that directory than
    this constant.

-   `INPUTZIP`, `OUTPUTZIP`

    Absolute paths to unique (per test program) temporary files
    with extension `.zip` that could be used arbitrarily by
    tests.  Except above facts tests should assume nothing about
    these files.

-   `TESTSTRING`, `TESTSTRINGLENGTH`, `TESTSTRINGCRC`

    A somewhat harmless, ASCII-only-but-multi-line test string,
    its length, and CRC.

-   `PATH_REL`, `PATH_ABS`, `PATH_ZIPFILE`, `PATH_ZIPDIR`, `PATH_ZIPABS`

    Enumerators used by functions `dataPath` and `testPath`,
    which see.


## Functions Provided by Package common

Package common provides the following auxilliary functions (which
are all exported by default):

-   `passThrough( $fromFile, $toFile, $action );`

    Reads archive `$fromFile`, executes `$action` on every member
    (or does nothing if `$action` is false), writes the resulting
    archive to `$toFile`.

-   `my $data = readFile( $file );`

    The ubiquitous file slurping function.

-   `my ( $outErr, $exitVal ) = execProc( $command );`

    The likewise ubiquitous process execution function.  Even if
    this function is exceedingly simple, please use it in favor
    of direct `qx{...}` or other constructs to have one
    consistent API.

-   `my ( $outErr, $exitVal ) = execPerl( @args );`

    Executes the Perl running the current test program with the
    specified arguments.

-   `my $file = dataPath( "simple" );`  
    `my $file = dataPath( "simple.zip" );`  
    `my $file = dataPath( "t/data/simple.zip" );`  

    Returns the path to the specified file below the `t/data`
    directory located below the build directory of this module
    ...

    `my $file = dataPath( "simple.zip", PATH_REL );`

    ... relative to the build directory with OS-specific path
    item separators (the default),

    `my $file = dataPath( "simple.zip", PATH_ABS );`

    ... as absolute path with OS-specific path item separators,

    `my $file = dataPath( "simple.zip", PATH_ZIPFILE );`

    ... relative to the build directory in Zip (internal) file
    name format, that is, always with forward slashes as path
    item separators,

    `my $file = dataPath( "simple.zip", PATH_ZIPDIR );`

    ... relative to the build directory in Zip (internal) file
    name format and with a final trailing slash,

    `my $file = dataPath( "simple.zip", PATH_ZIPABS );`

    ... as absolute path but with any volume specifier stripped
    and in Zip (internal) file name format.

-   `my $file = testPath( @pathItems, $pathType );`

    Returns the path to the specified file below the directory
    denoted by `TESTDIR` in the format specified by the optional
    path type, which is one of `PATH_REL` (the default),
    `PATH_ABS`, `PATH_ZIPFILE`, `PATH_ZIPDIR`, or `PATH_ZIPABS`,
    see above.


## Test Functions Provided by Package common

Package common provides below test functions (which are all
exported by default).  "Test functions" means that these
functions generate valid TAP and could (and should) be used
instead of Test::More functions where appropriate.

Note that some of the test functions rely on a particular
`$Archive::Zip::Errorhandler` being in place, so avoid using your
own handler unless you know what you are doing.

As usual, specification of the test name is optional.

-   `azbinis( $got, $expected, $name );`

    Test that succeeds like `is` from Test::More, but which
    provides additional diagnostics when comparison of lengthy
    binary `$got` and `$expected` fails.  Does not return any
    meaningful value.

-   `my $ok = azok( $status, $name );`

    Test that succeeds if `$status` equals `AZ_OK` and fails
    otherwise.  Provides built-in diagnostics in case of test
    failure and returns the test verdict.

-   `my $ok = azis( $status, $expectedStatus, $name );`  
    `my $ok = azis( $status, qr/$errorMatchingRegexp/, $name );`  
    `my $ok = azis( $status, $expectedStatus, qr/$errorMatchingRegexp/, $name );`  

    Test that succeeds if the specified status equals the
    expected status (one of the `:ERROR_CODES` constants) and/or,
    if an error has been generated, if the error message matches
    the specified regexp.  Provides built-in diagnostics in case
    of test failure and returns the test verdict.

-   `my $fileHandle = azopen( $file )`

    Creates and returns a file handle to write to the specified
    file (defaulting to `OUTPUTZIP`).  If possible, a piped file
    handle, otherwise a regular one.  Returns the undefined value
    on failure.

-   ```
    my $ok = azuztok( [['file' =>] $file,]
                      ['name'  => $name] );
    ```

    Test that succeeds if `unzip -t` on the specified file
    (defaulting to `OUTPUTZIP`) returns exit value zero.  This
    function provides built-in diagnostics in case of test
    failure and returns the test verdict regardless of the
    specific calling syntax.

-   ```
    my $ok = azuztok( [['file' =>] $file,]
                      'refzip' => $refzip,
                      ['name'  => $name] );
    ```

    Test that succeeds if `unzip -t` on the specified file
    returns the same exit value as `unzip -t` on the specified
    reference zip file.

-   ```
    my $ok = azuztok( [['file' =>] $file,]
                      'xppats' => $xppats,
                      ['name'  => $name] );
    ```

    Test that succeeds depending on the exit value of `unzip -t`
    on the specified file, its STDOUT and STDERR, and the
    operating system the test is running on.

    The expected patterns `$xppats` must be specified as a list
    of triples `[$exitVal, $outerrRegexp, $osName]`, like this:

    ```
    my $ok = azuztok( "emptyzip.zip",
                      'xppats' => [[0,     undef,         'freebsd'],
                                   [0,     undef,         'netbsd'],
                                   [undef, qr/\bempty\b/, undef]] );
    ```

    Meaning: Expect exit value zero on FreeBSD and NetBSD
    (disregarding STDOUT and STDERR on these), and expect STDOUT
    and STDERR matching `/\bempty\b/` on all other operating
    systems (disregarding exit value on these).

-   `azwok( $zip, %params )`

    Test (actually 6 of them) that succeeds if the specified
    archive can be written (both using a plain and a piped file
    handle) and tested using `unzip -t`.

    Accepts a hash of optional parameters `file`, `refzip`,
    `xppats`, `name`, which are processed as explained for
    function `azuztok`.  Does not return any meaningful value.
