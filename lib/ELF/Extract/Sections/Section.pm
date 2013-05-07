use strict;
use warnings;

package ELF::Extract::Sections::Section;

# ABSTRACT:  An Objective reference to a section in an ELF file.

use MooseX::Declare;

class ELF::Extract::Sections::Section {

=head1 DESCRIPTION

Generally Intended for use by L<ELF::Extract::Sections> as a meta-structure for tracking data,
but generated objects are returned to you for you to  deal with

=cut

=head1 SYNOPSIS

  use ELF::Extract::Sections::Section;

  my $s = ELF::Extract::Sections::Section->new(
      source => '/foo/bar.pl',
      name   => '.comment',
      offset => 45670,
      size   => 1244,
  );

  # prints a human friendly description
  print $s->to_string;

  # does likewise.
  print "$s";

  # Compare with another section ( preferably in the same file, meaningless otherwise )
  if( $s->compare( $y , 'name' ) ){

  }

  # Unimplemented
  $s->write_to ( file => '/tmp/out.txt' );

  # Retuns the sections contents as a string
  print $s->contents;

=cut

    use MooseX::Has::Sugar 0.0300;
    use MooseX::Types::Moose                ( ':all', );
    use ELF::Extract::Sections::Meta::Types ( ':all', );
    use MooseX::Types::Path::Tiny           ( 'File', );

    use overload '""' => \&to_string;

=head1 PUBLIC ATTRIBUTES

=cut

=head2 source

C<Str>|C<Path::Class::File>: Either a String or a Path::Class instance pointing to the file in mention.

=cut

    has source => ( isa => File, ro, required, coerce, );

=head2 name

C<Str>: The ELF Section Name

=cut

    has name => ( isa => Str, ro, required );

=head2 offset

C<Int>: Position in bytes relative to the start of the file.

=cut

    has offset => ( isa => Int, ro, required );

=head2 size

C<Int>: The ELF Section Size

=cut

    has size => ( isa => Int, ro, required );

=head1 PUBLIC METHODS

=cut

=head2 -> new ( %ATTRIBUTES )

4 Parameters, all required.

Returns an C<ELF::Extract::Sections::Section> object.

=cut

=head2 -> to_string

returns C<Str> description of the object

    [ Section {name} of size {size} in {file} @ {start} to {stop} ]

=cut

    method to_string ( Any $other?, Bool $polarity? ) {
        return sprintf
          q{[ Section %s of size %s in %s @ %x to %x ]},
          $self->name, $self->size, $self->source, $self->offset,
          $self->offset + $self->size,
          ;
    }

=head2 -> compare ( other => $other, field => $field )

2 Parameters, both required

=over 4

=item other

C<ELF::Extract::Sections::Section>: Item to compare with

=item field

C<Str['name','offset','size']>: Field to compare with.

=back

returns C<Int> of comparison result, between -1 and 1

=cut

    method compare ( ELF::Extract::Sections::Section :$other! , FilterField :$field! ) {
        if ( $field eq 'name' ) {
            return ( $self->name cmp $other->name );
        }
        if ( $field eq 'offset' ) {
            return ( $self->offset <=> $other->offset );
        }
        if ( $field eq 'size' ) {
            return ( $self->size <=> $other->size );
        }
        return;
    }

=head2 -> write_to ( file => $file )

B<UNIMPLEMENTED AS OF YET>

=over 4

=item file

C<Str>|C<Path::Class::File>: File target to write section contents to.

=back

=cut

    method write_to ( File :$file does coerce  ) {
        my $fh = $self->source->openr;
        seek $fh, $self->offset, 0;
        my $output     = $file->openw;
        my $chunksize  = 1024;
        my $bytes_left = $self->size;
        my $chunk = ( $bytes_left < $chunksize ) ? $bytes_left : $chunksize;
        while ( read $fh, my $buffer, $chunk ) {
            print {$output} $buffer or Carp::croak("Write to $file failed");
            $bytes_left -= $chunksize;
            $chunk = ( $bytes_left < $chunksize ) ? $bytes_left : $chunksize;
        }
        return 1;
    }

=head2 -> contents

returns C<Str> of binary data read out of file.

=cut

    method contents {
        my $fh = $self->source->openr;
        seek $fh, $self->offset, 0;
        my $b;
        read $fh, $b, $self->size;
        return $b;
    }
};

1;

__END__


