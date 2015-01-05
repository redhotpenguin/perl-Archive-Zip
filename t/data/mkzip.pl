#!/usr/bin/perl

#This script will create test zip files used by some of the tests.
#
#    File                Length  Streamed    Method
#    ===============================================
#    emptydef.zip        Yes     No          Deflate
#    emptydefstr.zip     Yes     Yes         Deflate
#    emptystore.zip      Yes     No          Store
#    emptystorestr.zip   Yes     Yes         Store
#


use warnings;
use strict;

use IO::Compress::Zip qw(:all);

my $time = 325532800;

zip \"" => "emptydef.zip", 
        Name => "fred", Stream => 0, Method => ZIP_CM_DEFLATE, Time => $time
    or die "Cannot create zip: $ZipError";

zip \"" => "emptydefstr.zip", 
        Name => "fred", Stream => 1, Method => ZIP_CM_DEFLATE, Time => $time
    or die "Cannot create zip: $ZipError";

zip \"" => "emptystore.zip", 
        Name => "fred", Stream => 0, Method => ZIP_CM_STORE, Time => $time
    or die "Cannot create zip: $ZipError";

zip \"" => "emptystorestr.zip", 
        Name => "fred", Stream => 1, Method => ZIP_CM_STORE, Time => $time
    or die "Cannot create zip: $ZipError";



zip \"abc" => "def.zip", 
        Name => "fred", Stream => 0, Method => ZIP_CM_DEFLATE, Time => $time
    or die "Cannot create zip: $ZipError";

zip \"abc" => "defstr.zip", 
        Name => "fred", Stream => 1, Method => ZIP_CM_DEFLATE, Time => $time
    or die "Cannot create zip: $ZipError";

zip \"abc" => "store.zip", 
        Name => "fred", Stream => 0, Method => ZIP_CM_STORE, Time => $time
    or die "Cannot create zip: $ZipError";

zip \"abc" => "storestr.zip", 
        Name => "fred", Stream => 1, Method => ZIP_CM_STORE, Time => $time
    or die "Cannot create zip: $ZipError";

