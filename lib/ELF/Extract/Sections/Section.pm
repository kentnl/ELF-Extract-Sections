use strict;
use warnings;
use MooseX::Declare;

class ELF::Extract::Sections::Section {
    our $VERSION = '0.0103';
    use MooseX::Has::Sugar 0.0300;
    use MooseX::Types::Moose                ( ':all', );
    use ELF::Extract::Sections::Meta::Types ( ':all', );
    use MooseX::Types::Path::Class          ( 'File', );

    use overload '""' => \&to_string;

    has source => (
        isa => File,
        ro, required, coerce => 1,
    );

    has name => ( isa => Str, ro, required );

    has offset => ( isa => Int, ro, required );

    has size => ( isa => Int, ro, required );

    #<<<
    method to_string ( Any $other?, Bool $polarity? ) {
    #>>>
              return sprintf(
                  qq{[ Section %s of size %s in %s @ %x to %x ]},
                  $self->name,   $self->size,
                  $self->source, $self->offset,
                  $self->offset + $self->size,
              );

        };

    #<<<
    method compare ( ELF::Extract::Sections::Section :$other! , FilterField :$field! ){
    #>>>
        if ( $field eq 'name' ) {
            return ( $self->name cmp $other->name );
        }
        if ( $field eq 'offset' ) {
            return ( $self->offset <=> $other->offset );
        }
        if ( $field eq 'size' ) {
            return ( $self->size <=> $other->size );
        }
        return undef;
    };

    #<<<
    method write_to( File :$file does coerce  ){
    #>>>
        my $fh = $self->source->openr;
          seek( $fh, $self->offset, 0 );
          my $output     = $file->openw;
          my $chunksize  = 1024;
          my $bytes_left = $self->size;
          my $chunk = ( $bytes_left < $chunksize ) ? $bytes_left : $chunksize;
          while ( read( $fh, my $buffer, $chunk ) ) {
            print {$output} $buffer;
            $bytes_left -= $chunksize;
            $chunk = ( $bytes_left < $chunksize ) ? $bytes_left : $chunksize;
        }
        return 1;
    };

    #<<<
    method contents {
    #>>>
        my $fh = $self->source->openr;
        seek( $fh, $self->offset, 0 );
        my $b;
        read( $fh, $b, $self->size );
        return $b;
    };
};

1;

__END__

=head1 NAME

ELF::Extract::Sections::Section - An Objective reference to a section in an ELF file.

=head1 VERSION

version 0.0103

=head1 Description

Generally Intended for use by L<ELF::Extract::Sections> as a meta-structure for tracking data,
but generated objects are returned to you for you to  deal with

=head1 Synopsis

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

    # Compare with another section ( preferably in the same file, meaningless otherwise
    if( $s->compare( $y , 'name' ) ){

    }

    # Unimplemented
    $s->write_to ( file => '/tmp/out.txt' );

    # Retuns the sections contents as a string
    print $s->contents;

=head1 Methods

=head2 -> new  ( %PARAMS )

4 Parameters, all required.

=over 4

=item source

C<Str>|C<Path::Class::File>: Either a String or a Path::Class instance pointing to the file in mention.

=item name

C<Str>: The ELF Section Name

=item size

C<Int>: The ELF Section Size

=item offset

C<Int>: Position in bytes relative to the start of the file.

=back

Returns an C<ELF::Extract::Sections::Section> object.


=head2 -> source

returns C<Path::Class::File>

=head2 -> name

returns C<Str>

=head2 -> offset

returns C<Int>

=head2 -> size

returns C<Int>

=head2 -> to_string

returns C<Str> description of the object

    [ Section {name} of size {size} in {file} @ {start} to {stop} ]

=head2 -> compare ( %PARAMS )

2 Parameters, both required

=over 4

=item other

C<ELF::Extract::Sections::Section>: Item to compare with

=item field

C<Str['name','offset','size']>: Field to compare with.

=back

returns C<Int> of comparison result, between -1 and 1

=head2 -> write_to ( %PARAMS )

B<UNIMPLEMENTED AS OF YET>

=over 4

=item file

C<Str>|C<Path::Class::File>: File target to write section contents to.

=back

=head2 -> contents

returns C<Str> of binary data read out of file.
