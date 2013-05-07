use strict;
use warnings;

package ELF::Extract::Sections::Meta::Types;
BEGIN {
  $ELF::Extract::Sections::Meta::Types::AUTHORITY = 'cpan:KENTNL';
}
{
  $ELF::Extract::Sections::Meta::Types::VERSION = '0.03000101';
}

# ABSTRACT: Generic Type Constraints for E:E:S

use MooseX::Types::Moose (':all');
use MooseX::Types -declare => [ 'FilterField', 'ElfSection' ];

subtype FilterField, as enum( [ 'name', 'offset', 'size', ] );

subtype ElfSection, as Object,
  where { $_->isa('ELF::Extract::Sections::Section') };

1;

__END__

=pod

=head1 NAME

ELF::Extract::Sections::Meta::Types - Generic Type Constraints for E:E:S

=head1 VERSION

version 0.03000101

=head1 Types

=head2 FilterField

ENUM: name, offset, size

=head2 ElfSection

An object that is a ELF::Extract::Sections::Section

=head1 AUTHOR

Kent Fredric <kentnl@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Kent Fredric.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
