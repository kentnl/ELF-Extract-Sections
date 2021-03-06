use 5.010;    # $+{}
use strict;
use warnings;

package ELF::Extract::Sections::Scanner::Objdump;

# ABSTRACT: An objdump based section scanner.

our $VERSION = '1.001005';

# AUTHORITY

use Moose qw( with has );
with 'ELF::Extract::Sections::Meta::Scanner';

use Carp qw( croak );
use MooseX::Has::Sugar 0.0300;

use MooseX::Types::Moose      (qw( Bool HashRef RegexpRef FileHandle Undef Str Int));
use MooseX::Types::Path::Tiny ('File');
use MooseX::Params::Validate  (qw( validated_list ));

=method C<open_file>

  my $boolean = $scanner->open_file( file => File );

Opens the file and assigns our state to that file.

L<ELF::Extract::Sections::Meta::Scanner/open_file>

=cut

sub open_file {
    my ( $self, $file ) = validated_list( \@_, file => { isa => File, }, );
    $self->log->debug("Opening $file");
    $self->_file($file);
    $self->_filehandle( $self->_objdump );
    return 1;
}

=method C<next_section>

  my $boolean = $scanner->next_section();

Advances our state to the next section.

L<ELF::Extract::Sections::Meta::Scanner/next_section>

=cut

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

=method C<section_offset>

  my $return = $scanner->section_offset(); # Int | Undef

Reports the offset of the currently open section

L<ELF::Extract::Sections::Meta::Scanner/section_offset>

=cut

sub section_offset {
    my ($self) = @_;
    if ( not $self->_has_state ) {
        $self->log->logcroak('Invalid call to section_offset outside of file scan');
        return;
    }
    return hex( $self->_state->{offset} );
}

=method C<section_size>

  my $return = $scanner->section_size(); # BANG

Dies, because this module can't compute section sizes.

L<ELF::Extract::Sections::Meta::Scanner/section_size>

=cut

sub section_size {
    my ($self) = @_;
    $self->log->logcroak('Can\'t perform section_size on this type of object.');
    return;
}

=method C<section_name>

  my $name = $scanner->section_name(); # Str | Undef

Returns the name of the current section

L<ELF::Extract::Sections::Meta::Scanner/section_name>

=cut

sub section_name {
    my ($self) = @_;
    if ( not $self->_has_state ) {
        $self->log->logcroak('Invalid call to section_name outside of file scan');
        return;
    }
    return $self->_state->{header};
}

=method C<can_compute_size>

  my $bool = $scanner->can_compute_size;

Returns false

L<ELF::Extract::Sections::Meta::Scanner/can_compute_size>

=cut

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
__PACKAGE__->meta->make_immutable;
no Moose;

sub _build__section_header_identifier {
    my ($self) = @_;
    my $header = $self->_header_regex;
    my $offset = $self->_offset_regex;

    return qr/${header}\s*${offset}:/;
}

sub _objdump_win32 {
    my ($self) = @_;
    require Capture::Tiny;
    ## no critic (Subroutines::ProhibitCallsToUnexportedSubs)
    my ( $stdout, $result ) = Capture::Tiny::capture_stdout(
        sub {
            system 'objdump', qw( -D -F ), $self->_file->realpath->absolute;
        },
    );
    if ( $result != 0 ) {
        $self->log->logconfess(qq{An error occured requesting section data from objdump $^E $@ });
    }
    open my $fh, '<', \$stdout or do {
        $self->log->logconfess(qq{An error occured making a string IO filehandle $! $@ });
    };
    return $fh;
}

sub _objdump {
    my ($self) = @_;
    if ( 'MSWin32' eq $^O or $ENV{OBJDUMP_SLURP} ) {
        return $self->_objdump_win32;
    }
    if ( open my $fh, q{-|}, q{objdump}, qw( -D -F ), $self->_file->realpath->absolute ) {
        return $fh;
    }
    $self->log->logconfess(qq{An error occured requesting section data from objdump $! $@ });
    return;
}

1;

__END__

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

=cut

=head1 IMPLEMENTS ROLES

=head2 ELF::Extract::Sections::Meta::Scanner

L<ELF::Extract::Sections::Meta::Scanner>

=cut
