use strict;
use warnings;
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

    use MooseX::Types -declare => [qw( FilterField IsTrue IsFalse )];

    BEGIN {
        subtype FilterField, as enum( [qw[ name offset size ]] );
        subtype IsTrue, as Bool,
                where { $_ },
                message { 'Boolean is not true' };
        subtype IsFalse, as  Bool,
                where {!$_ },
                where { 'Boolean is not false' };
    }

    has file => (
        is       => 'ro',
        isa      => File,
        required => 1,
        coerce   => 1,
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
    multi method sorted_sections(  FilterField :$field!, IsTrue :$descending! ) {
    #>>>
        return [
            sort { -( $a->compare( other => $b, field => $field ) ) }
              values %{ $self->sections }
        ];
    };
    #<<<
    multi method sorted_sections( FilterField :$field!, IsFalse :$descending?  ) {
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

=head1 Name

ELF::Extract::Sections - Extract Raw Chunks of data from identifiable ELF Sections

=head1 Version

Version 0.01 $Id:$

=head1 Caveats

=over 4

=item 1. Beta Software

This code is relatively new. It exists only as a best attempt at present until further notice. It
has proven practical for at least one application, and this is why the module exists. However, it can't be
guaranteed it will work for whatever you want it to in all cases. Please report any bugs you find.

=item 2. Feature Incomplete

This only presently has a very barebones functionality, which should however prove practical for most purposes.
If you have any suggestions, please tell me via "report bugs". If you never seek, you'll never find.

=item 3. Humans

This code is written by a human, and like all human code, it sucks. There will be bugs. Please report them.

=back

=head1 Synopsis

    use ELF::Extract::Sections;

    # Create an extractor object for foo.so
    my $extractor = ELF::Extract::Sections->new( file => '/path/to/foo.so' );

    # Scan file for section data, returns a hash
    my %sections  = ${ $extractor->sections };

    # Retreive the section object for the comment section
    my $data      = $sections{.comment};

    # Print the stringified explanation of the section
    print "$data";

    # Get the raw bytes out of the section.
    print $data->contents  # returns bytes

=head1 Methods

=head2 -> new ( file => FILENAME )

Creates A new Section Extractor object

=head2 -> file

Returns the file the section data is being created for.

=head2 -> sections

Returns a HashRef of the available sections.

=head2 -> sorted_sections ( SORT_BY )

=head2 -> sorted_sections ( SORT_BY, DESCENDING )

Returns an ArrayRef sorted by the SORT_BY field. May be Ascending or Descending depending on requirements.

=over 4

=item DESCENDING

Optional parameters. True for descending, False or absensent for ascending.

=item SORT_BY

A String of the field to sort by. Valid options at present are

=over 6

=item name

The Section Name

=item offset

The Sections offset relative to the start of the file.

=item size

The Size of the section.

=back

=back

=head1 Author

Kent Fredric, C<< <kentfredric at gmail.com> >>

=head1 Bugs

Please report any bugs or feature requests to C<bug-elf-extract-sections at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=ELF-Extract-Sections>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 Support

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


=head1 Acknowledgements


=head1 Copyright & License

Copyright 2009 Kent Fredric, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.


=cut

