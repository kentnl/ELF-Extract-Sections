package ELF::Extract::Sections::Meta::Types;
our $VERSION = '0.0103';


# ABSTRACT: Generic Type Contraints for E:E:S

# $Id:$
use strict;
use warnings;
use Moose;

use MooseX::Types::Moose (':all');
use MooseX::Types -declare => [ 'FilterField', 'ElfSection' ];

subtype FilterField, as enum( [ 'name', 'offset', 'size', ] );

subtype ElfSection, as Object, where { $_->isa('ELF::Extract::Sections::Section') };

1;



=pod

=head1 NAME

ELF::Extract::Sections::Meta::Types - Generic Type Contraints for E:E:S

=head1 VERSION

version 0.0103

=head1 Types

=head2 FilterField

ENUM: name, offset, size 

=head2 ElfSection 

An object that isa ELF::Extract::Sections::Section

=head1 AUTHOR

  Kent Fredric <kentnl@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2009 by Kent Fredric.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut



__END__

