package ELF::Extract::Sections::Meta::Types;

# $Id:$
use strict;
use warnings;
use Moose;

our $VERSION = '0.0103';

use MooseX::Types::Moose (':all');
use MooseX::Types -declare => [ 'FilterField', 'ElfSection' ];

subtype FilterField, as enum( [ 'name', 'offset', 'size', ] );

subtype ElfSection, as Object, where { $_->isa('ELF::Extract::Sections::Section') };

1;
__END__

=head1 NAME

ELF::Extract::Sections::Meta::Types - Generic Type Contraints for E:E:S

=head1 VERSION

version 0.0103

=head1 Types

=head2 FilterField

ENUM: name, offset, size 

