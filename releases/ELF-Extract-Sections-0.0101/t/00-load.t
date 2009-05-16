#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'ELF::Extract::Sections' );
}

diag( "Testing ELF::Extract::Sections $ELF::Extract::Sections::VERSION, Perl $], $^X" );
