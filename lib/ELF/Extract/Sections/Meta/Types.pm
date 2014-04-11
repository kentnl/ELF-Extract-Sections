use strict;
use warnings;

package ELF::Extract::Sections::Meta::Types;

# ABSTRACT: Generic Type Constraints for E:E:S

# AUTHORITY

use MooseX::Types::Moose (':all');
use MooseX::Types -declare => [ 'FilterField', 'ElfSection' ];

subtype FilterField, as enum( [ 'name', 'offset', 'size', ] );

subtype ElfSection, as Object,
  where { $_->isa('ELF::Extract::Sections::Section') };

1;
__END__

=head1 Types

=head2 FilterField

ENUM: name, offset, size

=head2 ElfSection

An object that is a ELF::Extract::Sections::Section
