#!/usr/bin/perl

# See https://github.com/redhotpenguin/perl-Archive-Zip/blob/master/t/README.md
# for a short documentation on the Archive::Zip test infrastructure.

use strict;

BEGIN { $^W = 1; }

use Test::More tests => 15;

use Archive::Zip qw();
use Archive::Zip::MemberRead;

use lib 't';
use common;

my $nl = $^O eq 'MSWin32' ? "\r\n" : "\n";

# normalize newlines for the platform we are running on
sub norm_nl($) { local $_ = shift; s/\r?\n/$nl/g; return $_; }

my $data = norm_nl(<<"EOF");
One Line
Two Lines
</tag>
Three Lines
Four Lines
Five Lines
</tag>
Quant
Bant
</tag>
Zapta
EOF

my $zip;
{
    my $filename = testPath("member_read_xml_like1.zip");
    $zip = new Archive::Zip;

    isa_ok($zip, "Archive::Zip", "Testing that \$zip is an Archive::Zip");
    isa_ok($zip->addString($data, "string.txt"), "Archive::Zip::Member");

    azok($zip->writeToFileNamed($filename));
}

{
    # Testing for normal line-based reading.

    my $member = $zip->memberNamed("string.txt");
    my $fh     = $member->readFileHandle();

    ok($fh, "Filehandle is valid");

    is($fh->getline(), "One Line",
        "Testing the first line in a normal read.");

    is($fh->getline(), "Two Lines",
        "Testing the second line in a normal read.");
}

{
    # Testing for setting the input record separator of the Perl
    # global variable.

    local $/ = "</tag>\n";

    my $member = $zip->memberNamed("string.txt");
    my $fh     = $member->readFileHandle();

    ok($fh, "Filehandle is valid");

    is(
        $fh->getline(),
        norm_nl("One Line\nTwo Lines\n"),
        "Testing the first \"line\" when \$/ is set."
    );

    is(
        $fh->getline(),
        norm_nl("Three Lines\nFour Lines\nFive Lines\n"),
        "Testing the second \"line\" when \$/ is set."
    );
}

{
    # Testing for setting input_record_separator in the filehandle.

    my $member = $zip->memberNamed("string.txt");
    my $fh     = $member->readFileHandle();

    ok($fh, "Filehandle is valid");

    $fh->input_record_separator("</tag>\n");

    is(
        $fh->getline(),
        norm_nl("One Line\nTwo Lines\n"),
        "Testing the first line when input_record_separator is set."
    );

    is(
        $fh->getline(),
        norm_nl("Three Lines\nFour Lines\nFive Lines\n"),
        "Testing the second line when input_record_separator is set."
    );
}

{
    # Test setting both input_record_separator in the filehandle
    # and in Perl.

    local $/ = "</t";

    my $member = $zip->memberNamed("string.txt");
    my $fh     = $member->readFileHandle();

    ok($fh, "Filehandle is valid");

    $fh->input_record_separator(" ");

    is($fh->getline(), "One",
        "Testing the first \"line\" in a both set read");

    is($fh->getline(), norm_nl("Line\nTwo"),
        "Testing the second \"line\" in a both set read.");
}
