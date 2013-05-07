use strict;
use warnings;

package ELF::Extract::Sections::Meta::Scanner;

# ABSTRACT: Interface Contract for Scanners

# $Id:$

use MooseX::Declare;

role ELF::Extract::Sections::Meta::Scanner with MooseX::Log::Log4perl {

    requires(
        'open_file',      'next_section',
        'section_offset', 'section_size',
        'section_name',   'can_compute_size'
    );

};

1;

__END__

=head1 Required Methods for Applying Roles

=head2 -> open_file file => FILE

Must take a file name and assume a state reset.

=head2 -> next_section

Must return true if a section was discovered.
Must return false otherwise.
This method is called before getting data out.

=head2 -> section_offset

Returns the offset as an Integer

=head2 -> section_size

Returns the sections computed size ( if possible )
If you can't compute the size, please call $self->log->logcroak()

=head2 -> section_name

Returns the sections name

=head2 -> can_compute_size

This returns whether or not this code is capable of discerning section sizes on its own.
return 1 if true, return C<undef> otherwise.

This will make us try guessing how big sections are by sorting them.
