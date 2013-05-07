use strict;
use warnings;

use Test::More tests => 4;    # last test to print

use FindBin;
use File::Find::Rule;
use Path::Class qw( file dir );
use YAML::XS;
use Log::Log4perl qw( :easy );

#Log::Log4perl->easy_init($WARN);

my $filesdir = "$FindBin::Bin/test_files/";

use ELF::Extract::Sections;

my $exclude = File::Find::Rule->name( "*.pl", "*.yaml" );
my @files = File::Find::Rule->file->not($exclude)->in($filesdir);

for my $file (@files) {
    my $f       = file($file);
    my $yaml    = file( $file . '.yaml' );
    my $data    = YAML::XS::LoadFile( $yaml->stringify );
    my $scanner = ELF::Extract::Sections->new( file => $f );
    my $d       = {};
    for ( values %{ $scanner->sections } ) {
        $d->{ $_->name } = {
            size   => $_->size,
            offset => $_->offset,
        };
    }
    is_deeply( $d, $data, sprintf 'Analysis of %s matches data stored in %s',
        $f->basename, $yaml->basename );
}

