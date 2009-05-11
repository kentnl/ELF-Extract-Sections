# $Id:$
use strict;
use warnings;
use MooseX::Declare;

#<<<
class ELF::Extract::Sections::Scanner::Objdump
with ELF::Extract::Sections::Meta::Scanner {
#>>>
    our $VERSION = '0.01.00';
    use MooseX::Types::Moose qw( Bool HashRef RegexpRef FileHandle );
    use MooseX::Types::Path::Class qw( File );

    has _header_regex => (
        isa     => RegexpRef,
        is      => 'ro',
        default => sub {
            return qr/<(?<header>[^>]+)>/;
        },
    );

    has _offset_regex => (
        isa     => RegexpRef,
        is      => 'ro',
        default => sub {
            return qr/\(File Offset:\s*(?<offset>0x[0-9a-f]+)\)/;
        },
    );

    has _section_header_identifier => (
        isa        => RegexpRef,
        is         => 'ro',
        required   => 0,
        lazy_build => 1,
    );

    has _file => (
        isa      => File,
        is       => 'rw',
        required => 0,
        clearer  => '_clear_file',
    );

    has _filehandle => (
        isa      => FileHandle,
        is       => 'rw',
        required => 0,
        clearer  => '_clear_filehandle',
    );

    has _state => (
        isa       => HashRef,
        is        => 'rw',
        required  => 0,
        predicate => '_has_state',
        clearer   => '_clear_state',
    );

    #
    # Interface Methods
    #
    #<<<
    method open_file ( File :$file! ){
    #>>>
        $self->log->debug("Opening $file");
          $self->_file($file);
          $self->_filehandle( $self->_objdump );
          return 1;
      }

      method next_section {
        my $re = $self->_section_header_identifier;
        my $fh = $self->_filehandle;
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

    method section_offset {
        if ( not $self->_has_state ) {
            $self->log->logcroak(
                'Invalid call to section_offset outside of file scan');
            return;
        }
        return hex( $self->_state->{offset} );
    }

    method section_size {
        $self->log->logcroak(
            'Can\'t perform section_size on this type of object.');
    }

    method section_name {
        if ( not $self->_has_state ) {
            $self->log->logcroak(
                'Invalid call to section_name outside of file scan');
        }
        return $self->_state->{header};
    }

    method can_compute_size {
        return 0;
    }

    #
    # Internals
    #

    #<<<
    method _build__section_header_identifier {
    #>>>
        my $header = $self->_header_regex;
        my $offset = $self->_offset_regex;

        return qr/${header}\s*${offset}:/;
    #<<<
    }
    #>>>

    #<<<
    method _objdump {
    #>>>
        if ( open my $fh,
            '-|', 'objdump', qw( -D -F ), $self->_file->cleanup->absolute )
        {
            return $fh;
        }
        $self->log->logconfess(
            qq{An error occured requesting section data from objdump $^ $@ });
        return;
    #<<<
    }
    #>>>

#<<<
}
#>>>
1;

__END__

=head1 Name

ELF::Extract::Sections::Scanner::Objdump - An C<objdump> based section scanner.

=head1 Description

This module is a model implementaiton of a Naive and system relaint ELF Section detector.
Its currently highly inefficient due to having to run the entire ELF through a disassembly
process to determine the section positions and only I<guesses> at section lengths by
advertisng that it cant' compute sizes.

=head1 Does

This module is a Performer of L<ELF::Extract::Sections::Meta::Scanner>

=head1 Methods

See  L<ELF::Extract::Sections::Meta::Scanner> for a method breakdown.

=head1 Synopsis

TO use this module, simply initialise L<ELF::Extract::Sections> as so

    my $extractor  = ELF::Extract::Sections->new(
            file => "/path/to/file.so" ,
            scanner => "Objdump",
    );

