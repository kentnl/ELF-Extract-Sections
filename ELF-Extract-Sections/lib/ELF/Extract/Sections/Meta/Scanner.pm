package ELF::Extract::Sections::Meta::Scanner;

# $Id:$
use strict;
use warnings;

use Moose::Role;

use namespace::clean -except => [qw( meta )];

with 'MooseX::Log::Log4perl';

requires
  qw( open_file next_section section_offset section_size section_name can_compute_size );

1;

__END__

=head1 Required Methods for Applying Roles

=head2 -> open_file file => FILE

Must take a filename and assume a state reset. 

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

This retuns wether or not this code is capable of discerning section sizes on its own. 
return 1 if true, return undef otherwise. 

This will make us try guessing how big sections are by sorting them.
