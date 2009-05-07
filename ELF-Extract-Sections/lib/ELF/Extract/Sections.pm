use 5.010;
use MooseX::Declare;
our $VERSION = '0.01';

#<<<
class ELF::Extract::Sections with MooseX::Log::Log4perl {
#>>>
    use MooseX::Types::Moose qw( Bool HashRef RegexpRef );
    use MooseX::Types::Path::Class qw( File );
    use Carp                  ();
    use ELF::Extract::Section ();
    use MooseX::MultiMethods;

    use MooseX::Types -declare => [qw( FilterField )];

    BEGIN {
        subtype FilterField, as enum( [qw[ name offset size ]] );
    }

    has file => (
        is       => 'ro',
        isa      => File,
        required => 1,
        coerce   => 1,
    );

    has debug => (
        is       => 'ro',
        isa      => Bool,
        required => 0,
        default  => 0,
    );

    has sections => (
        isa        => 'HashRef[ELF::Extract::Section]',
        is         => 'ro',
        required   => 0,
        lazy_build => 1,
    );

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

    #<<<
    method BUILD( $args ) {
    #>>>
        if ( not $self->file->stat ) {
            $self->log->logconfess(q{File Specifed could not be found.});
        }
    #<<<
    }
    #>>>

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
            '-|', 'objdump', qw( -D -F ), $self->file->cleanup->absolute )
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
    method _stash_record ( HashRef $stash! , Str $header!, Str $offset! ){
    #>>>
        $self->log->info("objdump -D -F : Section $header at $offset");
          my $o = hex($offset);
          if ( exists $stash->{$o} ) {
            $self->log->logcluck(

                q{Warning, duplicate file offset reported by objdump. }
                  . $stash->{$o}
                  . qq( and $header collide at $offset )
                  . q( Assuming )
                  . $stash->{$o}
                  . q( is empty and replacing it )

            );
        }
        $stash->{$o} = $header;
    #<<<
    }
    #>>>

    #<<<
    method _build_offset_table ( FileHandle $fh! ){
    #>>>
        my $re = $self->_section_header_identifier;

          my %offsetStash = ();
          while ( my $line = <$fh> ) {
            next if ( $line !~ $re );
            my ( $header, $offset ) = ( $+{header}, $+{offset} );
            $self->_stash_record( \%offsetStash, $header, $offset, );
        }
        return \%offsetStash;
    #<<<
    }
    #>>>

    #<<<
    method _build_section_section( Str $stashName, Int $start, Int $stop , File $file ){
    #>>>
        $self->log->info(" Section ${stashName} , ${start} -> ${stop} ");
          return ELF::Extract::Section->new(
            offset => $start,
            size   => $stop - $start,
            name   => $stashName,
            source => $file,
          );
    #<<<
    }
    #>>>

    #<<<
    method _build_section_table ( HashRef $ob! ){
    #>>>
        my %dataStash = ();
          my @k       = sort { $a <=> $b } keys %{$ob};
          my $i       = 0;
          while ( $i < $#k ) {
            $dataStash{ $ob->{ $k[$i] } } = $self->_build_section_section(
                $ob->{ $k[$i] },
                $k[$i], $k[ $i + 1 ],
                $self->file
            );
            $i++;
        }
        return \%dataStash;
    #<<<
    }
    #>>>

    #<<<
    method _build_sections {
    #>>>
        use Data::Dumper;

        $self->log->debug('Building Section List');

        return $self->_build_section_table(
            $self->_build_offset_table( $self->_objdump ) );
    #<<<
    }
    #>>>

    #<<<
    method section_names {
    #>>>
        my $filehandle = $self->file->openr
          or
          $self->log->logcroak( sprintf q{Can't Read %s: %s}, $self->file, $! );
    #<<<
    }
    #>>>

    #<<<
    multi method sorted_sections(  FilterField :$field!, Bool :$descending! where { $_ }  ) {
    #>>>
        return [
            sort { -( $a->compare( other => $b, field => $field ) ) }
              values %{ $self->sections }
        ];
    };
    #<<<
    multi method sorted_sections( FilterField :$field!, Bool :$descending? where { !$_ } ) {
    #>>>
        return [
            sort { $a->compare( other => $b, field => $field ) }
              values %{ $self->sections }
        ];
    #<<<
    }
    #>>>
#<<<
}
#>>>

1;

__END__

=head1 NAME

ELF::Extract::Sections - The great new ELF::Extract::Sections!

=head1 VERSION

Version 0.01 $Id:$

=cut

=head1 SYNOPSIS

Quick summary of what the module does.

Perhaps a little code snippet.

    use ELF::Extract::Sections;

    my $foo = ELF::Extract::Sections->new();
    ...

=head1 EXPORT

A list of functions that can be exported.  You can delete this section
if you don't export anything, such as for a purely object-oriented module.

=head1 FUNCTIONS

=head2 function1

=cut

=head2 function2

=cut

=head1 AUTHOR

Kent Fredric, C<< <kentfredric at gmail.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-elf-extract-sections at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=ELF-Extract-Sections>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc ELF::Extract::Sections


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=ELF-Extract-Sections>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/ELF-Extract-Sections>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/ELF-Extract-Sections>

=item * Search CPAN

L<http://search.cpan.org/dist/ELF-Extract-Sections/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 COPYRIGHT & LICENSE

Copyright 2009 Kent Fredric, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.


=cut

