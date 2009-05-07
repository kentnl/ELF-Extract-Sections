use 5.010;
use MooseX::Declare;
our $VERSION = '0.01';




class ELF::Extract::Section {

    use MooseX::Types::Moose qw( Str Int );
    use MooseX::Types::Path::Class qw( File );

    use overload '""' => \&to_string;
    use MooseX::Types -declare => [qw( FilterField )];

    BEGIN {
    subtype FilterField, as enum([qw[ name offset size ]]);
    }
    has source => (
        isa      => File,
        is       => 'ro',
        required => 1,
    );

    has name => (
        isa      => Str,
        is       => 'rw',
        required => 1,
    );

    has offset => (
        isa      => Int,
        is       => 'rw',
        required => 1,
    );

    has size => (
        isa      => Int,
        is       => 'rw',
        required => 1,
    );

    method to_string ( Any $other, Bool $polarity ) {
        return sprintf(
        qq{[ Section %s of size %s in %s @ %x to %x ]},
        $self->name,
        $self->size,
        $self->source,
        $self->offset,
        $self->offset + $self->size
        );

    }

    method compare ( ELF::Extract::Section :$other , FilterField :$field ){
        if ( $field eq 'name' ){
            return ( $self->name cmp $other->name );
        }
        if ( $field eq 'offset' ){
            return ( $self->offset <=> $other->offset );
        }
        if ( $field eq 'size' ){
            return ( $self->size <=> $other->size );
        }
        return undef;
    }
};

1;

