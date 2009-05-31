#!/usr/bin/perl 

use strict;
use warnings;

use FindBin;
use File::Find::Rule;
use YAML::XS;
use Path::Class qw( file dir );
use lib "$FindBin::Bin/../../lib";
use ELF::Extract::Sections;

my $exclude = File::Find::Rule->name( "*.pl", "*.yaml" );
my @files = File::Find::Rule->file->not($exclude)->in("$FindBin::Bin");
for my $file (@files) {
    my $f        = file($file);
    my $yamlfile = file( $file . ".yaml" );

    my $scanner = ELF::Extract::Sections->new( file => $f );
    my $d = {};
    for ( values %{ $scanner->sections } ) {
        $d->{ $_->name } = {
            size   => $_->size,
            offset => $_->offset,
        };
    }
    my $fh = $yamlfile->openw;
    print $fh YAML::XS::Dump($d);
}
