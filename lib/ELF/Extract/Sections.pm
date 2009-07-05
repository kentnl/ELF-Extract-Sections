use strict;
use warnings;
use MooseX::Declare;

#<<<
class ELF::Extract::Sections with MooseX::Log::Log4perl {
#>>>
    our $VERSION = '0.0103';
    use MooseX::Has::Sugar 0.0300;
    use MooseX::Types::Moose                ( ':all', );
    use MooseX::Types::Path::Class          ( 'File', );
    use ELF::Extract::Sections::Meta::Types ( ':all', );

    require ELF::Extract::Sections::Section;

    has file => ( isa => File, ro, required, coerce, );
    has scanner => ( isa => Str, default => 'Objdump', ro, );
    has sections => ( isa => HashRef [ElfSection], ro, lazy_build, );
    has _scanner_package  => ( isa => ClassName, ro, lazy_build, );
    has _scanner_instance => ( isa => Object,    ro, lazy_build, );

    #
    # Public Interfaces
    #

    #<<<
    method sorted_sections(  FilterField :$field!, Bool :$descending? ) {
    #>>>
        my $m = 1;
          $m = -1 if ($descending);
          return [ sort { $m * ( $a->compare( other => $b, field => $field ) ) } values %{ $self->sections } ];
    };

    #
    # Moose Builders
    #

    method _build__scanner_package {
        my $pkg = 'ELF::Extract::Sections::Scanner::' . $self->scanner;
        eval "use $pkg; 1"
          or $self->log->logconfess( "The Scanner " . $self->scanner . " could not be found as $pkg. >$! >$@ " );
        return $pkg;
    };

    method _build__scanner_instance {
        my $instance = $self->_scanner_package->new();
        return $instance;
    };

    method _build_sections {
        $self->log->debug('Building Section List');
        if ( $self->_scanner_instance->can_compute_size ) {
            return $self->_scan_with_size;
        }
        else {
            return $self->_scan_guess_size;
        }
    };

    #<<<
    method BUILD( $args ) {
    #>>>
        if ( not $self->file->stat ) {
            $self->log->logconfess(q{File Specifed could not be found.});
        }
    };

    #
    # Internals
    #
    #<<<
    method _stash_record ( HashRef $stash! , Str $header!, Str $offset! ){
    #>>>
        if ( exists $stash->{$offset} ) {
            $self->log->logcluck(

                q{Warning, duplicate file offset reported by scanner. }
                  . $stash->{$offset}
                  . qq( and $header collide at $offset )
                  . q( Assuming )
                  . $stash->{$offset}
                  . q( is empty and replacing it )

            );
        }
        $stash->{$offset} = $header;
    };

    #<<<
    method _build_section_section( Str $stashName, Int $start, Int $stop , File $file ){
    #>>>
        $self->log->info(" Section ${stashName} , ${start} -> ${stop} ");
          return ELF::Extract::Sections::Section->new(
            offset => $start,
            size   => $stop - $start,
            name   => $stashName,
            source => $file,
          );
    };

    #<<<
    method _build_section_table ( HashRef $ob! ){
    #>>>
        my %dataStash = ();
          my @k       = sort { $a <=> $b } keys %{$ob};
          my $i       = 0;
          while ( $i < $#k ) {
            $dataStash{ $ob->{ $k[$i] } } = $self->_build_section_section( $ob->{ $k[$i] }, $k[$i], $k[ $i + 1 ], $self->file );
            $i++;
        }
        return \%dataStash;
    };

    method _scan_guess_size {
        $self->_scanner_instance->open_file( file => $self->file );
        my %offsets = ();
        while ( $self->_scanner_instance->next_section() ) {
            my $name   = $self->_scanner_instance->section_name;
            my $offset = $self->_scanner_instance->section_offset;
            $self->_stash_record( \%offsets, $name, $offset );
        }
        return $self->_build_section_table( \%offsets );
    };

    method _scan_with_size {
        my %dataStash = ();
        $self->_scanner_instance->open_file( file => $self->file );
        while ( $self->_scanner_instance->next_section() ) {
            my $name   = $self->_scanner_instance->section_name;
            my $offset = $self->_scanner_instance->section_offset;
            my $size   = $self->_scanner_instance->section_size;

            $dataStash{$name} = $self->_build_section_section( $name, $offset, $offset + $size, $self->file );
        }
        return \%dataStash;
    };

#<<<
}
#>>>
1;

__END__

=head1 NAME

ELF::Extract::Sections - Extract Raw Chunks of data from identifiable ELF Sections

=head1 VERSION

version 0.0103

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

=head2 -> sorted_sections ( field => SORT_BY )

=head2 -> sorted_sections ( field => SORT_BY, descending => DESCENDING )

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

=head1 Debugging

This library uses L<Log::Log4perl>. To see more verbose processing notices, do this:

    use Log::Log4perl qw( :easy );
    Log::Log4perl->easy_init($DEBUG);

For convenience to make sure you don't happen to miss this fact, we never initialize Log4perl ourself, so it will
spit the following message if you have not set it up:

    Log4perl: Seems like no initialization happened. Forgot to call init()?

To suppress this, just do

    use Log::Log4perl qw( :easy );

I request however you B<don't> do that for modules intended to be consumed by others without good cause.

=head1 Author

Kent Fredric, C<< <kentnl@cpan.org> >>

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

