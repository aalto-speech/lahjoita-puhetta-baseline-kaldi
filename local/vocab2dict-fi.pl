#!/usr/bin/perl -w
#
# Reads a list of Finnish words or morphs, one per line, in UTF-8 encoding, and
# creates a CMUdict style pronunciation dictionary for Kaldi.

use strict;
use locale;
use Encode;
use POSIX;
use Getopt::Long;
use utf8;
use vars qw/$m/;

my $input_file = "-";
my $morph_model = "";
my $options_ok = GetOptions(
	"read=s" => \$input_file,
	"morph"  => \$morph_model);
if (!$options_ok) {
	die "Invalid command line options."
}

open(my $INPUT, "< $input_file") or die "Cannot open $input_file: $!";

print ".laugh SPN\n";
print ".cough SPN\n";
print ".sigh SPN\n";
print ".yawn SPN\n";
print ".br SPN\n";
print ".ct SPN\n";
print ".fp NSN\n";
print ".pause NSN\n";

while (<$INPUT>) {
	chomp;
	my $word = decode( "utf8", $_ );
	next if ( $word eq '' );
	next if ( $word eq '.laugh' );
	next if ( $word eq '.cough' );
	next if ( $word eq '.yawn' );
	next if ( $word eq '.sigh' );
	next if ( $word eq '.br' );
	next if ( $word eq '.ct' );
	next if ( $word eq '.fp' );
	next if ( $word eq '.pause' );

	print encode( "utf8", $word );

	# Convert foreign phonemes to Finnish representatives.
	$word =~ s/ch/ts/g;
	$word =~ s/č/ts/g;
	$word =~ s/c/k/g;
	$word =~ s/ñ/nj/g;
	$word =~ s/qu/kv/g;
	$word =~ s/q/k/g;
	$word =~ s/š/s/g;
	$word =~ s/w/v/g;
	$word =~ s/x/ks/g;
	$word =~ s/z/ts/g;
	$word =~ s/å/o/g;
	$word =~ s/à/a/g;
	$word =~ s/é/e/g;
	$word =~ s/ë/e/g;
	$word =~ s/í/i/g;
	$word =~ s/ó/o/g;
	$word =~ s/ú/u/g;
	$word =~ s/ý/y/g;
	$word =~ s/ü/yy/g;
	$word =~ s/æ/ä/g;
	$word =~ s/ø/ö/g;
	$word =~ s/'//g;     # vaa'an
	$word =~ s/þ/f/g;     # hafþór

	for ( my $pos = 0 ; $pos < length($word) ; ++$pos ) {
		my $letter = substr( $word, $pos, 1 );

		my $phone;
		if ($letter eq '-') {
			$phone = "SIL";
		}
		elsif ($letter eq 'ä') {
			$phone = "AE";
		}
		elsif ($letter eq 'ö') {
			$phone = "OE";
		}
        elsif ($letter eq '+') {
			$phone = "";
		}
		else {
			$phone = uc($letter);
		}
        if (length $phone > 0) {
		    print encode( "utf8", " $phone" );
        }
	}
	print "\n";
}
