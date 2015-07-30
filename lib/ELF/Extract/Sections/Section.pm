use 5.006;
use strict;
use warnings;

package ELF::Extract::Sections::Section;

# ABSTRACT:  An Objective reference to a section in an ELF file.

our $VERSION = '1.000000';

our $AUTHORITY = 'cpan:KENTNL'; # AUTHORITY

use Moose;






































use Carp qw( croak );
use MooseX::Has::Sugar 0.0300;
use MooseX::Types::Moose                ( ':all', );
use ELF::Extract::Sections::Meta::Types ( ':all', );
use MooseX::Types::Path::Tiny           ( 'File', );

use overload '""' => \&to_string;

sub _argument {
    my ( $args, $number, $type, %flags ) = @_;
    return if not $flags{required} and @{$args} < $number + 1;
    my $can_coerce = $flags{coerce} ? '(coerceable)': q[];

    @{$args} >= $number + 1 or croak "Argument $number of type $type$can_coerce was not specified";

    if ( not $flags{coerce} ) {
        $type->check( $args->[$number] ) and return $args->[$number];
    }
    else {
        my $value = $type->coerce( $args->[$number] );
        return $value if $value;
    }
    return croak "Argument $number was not of type $type$can_coerce: " . $type->get_message( $args->[$number] );

}

sub _parameter {
    my ( $args, $name, $type, %flags ) = @_;
    return if not $flags{required} and not exists $args->{$name};
    my $can_coerce = $flags{coerce} ? '(coerceable)': q[];
    exists $args->{$name} or croak "Parameter '$name' of type $type$can_coerce was not specified";

    if ( not $flags{coerce} ) {
        $type->check( $args->{$name} ) and return delete $args->{$name};
    }
    else {
        my $value = $type->coerce( delete $args->{$name} );
        return $value if $value;
    }
    return croak "Parameter \'$name\' was not of type $type$can_coerce: " . $type->get_message( $args->{$name} );
}











has source => ( isa => File, ro, required, coerce, );







has name => ( isa => Str, ro, required );







has offset => ( isa => Int, ro, required );







has size => ( isa => Int, ro, required );

__PACKAGE__->meta->make_immutable;
no Moose;





















sub to_string {
    my ( $self, @args ) = @_;
    @args < 3 or croak 'Too many arguments';
    my $other    = _argument( \@args, 0, Any,  required => 0 );
    my $polarity = _argument( \@args, 1, Bool, required => 0 );
    return sprintf
      q{[ Section %s of size %s in %s @ %x to %x ]},
      $self->name, $self->size, $self->source, $self->offset,
      $self->offset + $self->size,
      ;
}





















sub compare {
    my ( $self, %args ) = @_;
    my $other = _parameter( \%args, 'other', class_type('ELF::Extract::Sections::Section'), required => 1 );
    my $field = _parameter( \%args, 'field', FilterField, required => 1 );
    if ( keys %args ) {
        croak "Unknown parameters @{[ keys %args ]}";
    }

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















sub write_to {
    my ( $self, %args ) = @_;
    my $file = _parameter( \%args, 'file', File, required => 1, coerce => 1  );
    if ( keys %args ) {
        croak "Unknown parameters @{[ keys %args ]}";
    }
    my $fh = $self->source->openr;
    seek $fh, $self->offset, 0;
    my $output     = $file->openw;
    my $chunksize  = 1024;
    my $bytes_left = $self->size;
    my $chunk      = ( $bytes_left < $chunksize ) ? $bytes_left : $chunksize;
    while ( read $fh, my $buffer, $chunk ) {
        print {$output} $buffer or Carp::croak("Write to $file failed");
        $bytes_left -= $chunksize;
        $chunk = ( $bytes_left < $chunksize ) ? $bytes_left : $chunksize;
    }
    return 1;
}







sub contents {
    my ($self) = @_;
    my $fh = $self->source->openr;
    seek $fh, $self->offset, 0;
    my $b;
    read $fh, $b, $self->size;
    return $b;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

ELF::Extract::Sections::Section - An Objective reference to a section in an ELF file.

=head1 VERSION

version 1.000000

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

=head1 DESCRIPTION

Generally Intended for use by L<ELF::Extract::Sections> as a meta-structure for tracking data,
but generated objects are returned to you for you to  deal with

=head1 PUBLIC ATTRIBUTES

=head2 source

C<Str>|C<Path::Tiny>: Either a String or a Path::Tiny instance pointing to the file in mention.

=head2 name

C<Str>: The ELF Section Name

=head2 offset

C<Int>: Position in bytes relative to the start of the file.

=head2 size

C<Int>: The ELF Section Size

=head1 PUBLIC METHODS

=head2 -> new ( %ATTRIBUTES )

4 Parameters, all required.

Returns an C<ELF::Extract::Sections::Section> object.

=head2 -> to_string

returns C<Str> description of the object

    [ Section {name} of size {size} in {file} @ {start} to {stop} ]

=head2 -> compare ( other => $other, field => $field )

2 Parameters, both required

=over 4

=item other

C<ELF::Extract::Sections::Section>: Item to compare with

=item field

C<Str['name','offset','size']>: Field to compare with.

=back

returns C<Int> of comparison result, between -1 and 1

=head2 -> write_to ( file => $file )

B<UNIMPLEMENTED AS OF YET>

=over 4

=item file

C<Str>|C<Path::Tiny>: File target to write section contents to.

=back

=head2 -> contents

returns C<Str> of binary data read out of file.

=head1 AUTHOR

Kent Fredric <kentnl@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Kent Fredric <kentfredric@gmail.com>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
