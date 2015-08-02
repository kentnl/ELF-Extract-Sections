use 5.006;
use strict;
use warnings;

package ELF::Extract::Sections::Meta::Types;

# ABSTRACT: Generic Type Constraints for E:E:S

our $VERSION = '1.000001';

# AUTHORITY

use MooseX::Types::Moose (qw( Object ));
use MooseX::Types -declare => [ 'FilterField', 'ElfSection' ];

## no critic (ProhibitCallsToUndeclaredSubs)
subtype FilterField, as enum( [ 'name', 'offset', 'size', ] );

subtype ElfSection, as Object, where { $_->isa('ELF::Extract::Sections::Section') };

1;
__END__

=head1 Types

=head2 C<FilterField>

ENUM: name, offset, size

=head2 C<ElfSection>

An object that is a ELF::Extract::Sections::Section
