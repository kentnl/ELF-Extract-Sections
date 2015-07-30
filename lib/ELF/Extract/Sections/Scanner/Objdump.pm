use 5.010; # $+{}
use strict;
use warnings;

package ELF::Extract::Sections::Scanner::Objdump;

# ABSTRACT: An C<objdump> based section scanner.

our $VERSION = '1.000000';

our $AUTHORITY = 'cpan:KENTNL'; # AUTHORITY

use Moose qw( with has );
with "ELF::Extract::Sections::Meta::Scanner";



































use Carp qw( croak );
use MooseX::Has::Sugar 0.0300;









use MooseX::Types::Moose (qw( Bool HashRef RegexpRef FileHandle Undef Str Int));









use MooseX::Types::Path::Tiny ('File');













sub _argument {
    my ( $args, $number, $type, %flags ) = @_;
    return if not $flags{required} and @{$args} < $number + 1;
    my $can_coerce = $flags{coerce} ? '' : '(coerceable)';

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
    my $can_coerce = $flags{coerce} ? '' : '(coerceable)';
    exists $args->{$name} or croak "Parameter \'$name\' of type $type$can_coerce was not specified";

    if ( not $flags{coerce} ) {
        $type->check( $args->{$name} ) and return delete $args->{$name};
    }
    else {
        my $value = $type->coerce( delete $args->{$name} );
        return $value if $value;
    }
    return croak "Parameter \'$name\' was not of type $type$can_coerce: " . $type->get_message( $args->{$name} );
}

sub open_file {
    my ( $self, %args ) = @_;
    my $file = _parameter( \%args, 'file', File, required => 1 );
    if ( keys %args ) {
        croak "Unknown parameters @{[ keys %args ]}";
    }
    $self->log->debug("Opening $file");
    $self->_file($file);
    $self->_filehandle( $self->_objdump );
    return 1;
}









sub next_section {
    my ($self) = @_;
    my $re     = $self->_section_header_identifier;
    my $fh     = $self->_filehandle;
    while ( my $line = <$fh> ) {
        next if $line !~ $re;
        my ( $header, $offset ) = ( $+{header}, $+{offset} );
        $self->_state( { header => $header, offset => $offset } );
        $self->log->info("objdump -D -F : Section $header at $offset");
        return 1;
    }
    $self->_clear_file;
    $self->_clear_filehandle;
    $self->_clear_state;
    return 0;
}









sub section_offset {
    my ($self) = @_;
    if ( not $self->_has_state ) {
        $self->log->logcroak('Invalid call to section_offset outside of file scan');
        return;
    }
    return hex( $self->_state->{offset} );
}









sub section_size {
    my ($self) = @_;
    $self->log->logcroak('Can\'t perform section_size on this type of object.');
    return;
}









sub section_name {
    my ($self) = @_;
    if ( not $self->_has_state ) {
        $self->log->logcroak('Invalid call to section_name outside of file scan');
        return;
    }
    return $self->_state->{header};
}









sub can_compute_size {
    return 0;
}















has _header_regex => (
    isa => RegexpRef,
    ro,
    default => sub {
        return qr/<(?<header>[^>]+)>/;
    },
);











has _offset_regex => (
    isa => RegexpRef,
    ro,
    default => sub {
        ## no critic (RegularExpressions::ProhibitEnumeratedClasses)
        return qr/[(]File Offset:\s*(?<offset>0x[0-9a-f]+)[)]/;
    },
);









has _section_header_identifier => ( isa => RegexpRef, ro, lazy_build, );











has _file => ( isa => File, rw, clearer => '_clear_file', );











has _filehandle => ( isa => FileHandle, rw, clearer => '_clear_filehandle', );















has _state => (
    isa => HashRef,
    rw,
    predicate => '_has_state',
    clearer   => '_clear_state',
);













sub _build__section_header_identifier {
    my ($self) = @_;
    my $header = $self->_header_regex;
    my $offset = $self->_offset_regex;

    return qr/${header}\s*${offset}:/;
}











sub _objdump {
    my ($self) = @_;
    if ( open my $fh, q{-|}, q{objdump}, qw( -D -F ), $self->_file->realpath->absolute ) {
        return $fh;
    }
    $self->log->logconfess(qq{An error occured requesting section data from objdump $^ $@ });
    return;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

ELF::Extract::Sections::Scanner::Objdump - An C<objdump> based section scanner.

=head1 VERSION

version 1.000000

=head1 SYNOPSIS

This module is a model implementation of a Naive and system reliant ELF Section detector.
Its currently highly inefficient due to having to run the entire ELF through a disassembly
process to determine the section positions and only I<guesses> at section lengths by
advertising that it can't compute sizes.

TO use this module, simply initialise L<ELF::Extract::Sections> as so

    my $extractor  = ELF::Extract::Sections->new(
            file => "/path/to/file.so" ,
            scanner => "Objdump",
    );

=head1 IMPLEMENTS ROLES

=head2 ELF::Extract::Sections::Meta::Scanner

L<ELF::Extract::Sections::Meta::Scanner>

=head1 DEPENDS

=head2 MooseX::Has::Sugar

Lots of keywords.

L<MooseX::Has::Sugar>

=head2 MooseX::Types::Moose

Type Constraining Keywords.

L<MooseX::Types::Moose>

=head2 MooseX::Types::Path::Tiny

File Type Constraints w/ Path::Tiny

L<MooseX::Types::Path::Tiny>

=head1 PUBLIC METHODS

=head2 -> open_file ( file => File ) : Bool I< ::Scanner >

Opens the file and assigns our state to that file.

L<ELF::Extract::Sections::Meta::Scanner/open_file>

=head2 -> next_section () : Bool I< ::Scanner >

Advances our state to the next section.

L<ELF::Extract::Sections::Meta::Scanner/next_section>

=head2 -> section_offset () : Int | Undef I< ::Scanner >

Reports the offset of the currently open section

L<ELF::Extract::Sections::Meta::Scanner/section_offset>

=head2 -> section_size () : Undef I< ::Scanner >

Dies, because this module can't compute section sizes.

L<ELF::Extract::Sections::Meta::Scanner/section_size>

=head2 -> section_name () : Str | Undef I< ::Scanner >

Returns the name of the current section

L<ELF::Extract::Sections::Meta::Scanner/section_name>

=head2 -> can_compute_size () : Bool I< ::Scanner >

Returns false

L<ELF::Extract::Sections::Meta::Scanner/can_compute_size>

=head1 PRIVATE ATTRIBUTES

=head2 _header_regex : RegexpRef

A regular expression for identifying the

  <asdasdead>

Style tokens that denote objdump header names.

Note: This is not XML.

=head2 _offset_regex : RegexpRef

A regular expression for identifying offset blocks in objdump's output.

They look like this:

  File Offset: 0xdeadbeef

=head2 _section_header_identifier : RegexpRef

A regular expression for extracting Headers and Offsets together

  <headername> File Offset: 0xdeadbeef

=head2 _file : File

A L<Path::Tiny> reference to a file somewhere on a system

=head3 _clear_file : _file.clearer

Clears L</_file>

=head2 _filehandle : FileHandle

A perl FileHandle that points to the output of objdump for L</_file>

=head3 _clear_file_handle : _filehandle.clearer

Clears L</_filehandle>

=head2 _state : HashRef

Keeps track of what we're doing, and what the next header is to return.

=head3 _has_state : _state.predicate

Returns is-set of L</_state>

=head3 _clear_state : _state.clearer

Clears L<_state>

=head1 PRIVATE ATTRIBUTE BUILDERS

=head2 -> _build__section_header_identifier : RegexpRef

Assembles L</_header_regex> and L</_offset_regex>

L</_section_header_identifier>

=head1 PRIVATE METHODS

=head2 -> _objdump : FileHandle | Undef

Calls the system C<objdump> instance for the currently processing file.

=head1 AUTHOR

Kent Fredric <kentnl@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Kent Fredric <kentfredric@gmail.com>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
