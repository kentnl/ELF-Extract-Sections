use strict;
use warnings;

package ELF::Extract::Sections;

# ABSTRACT: Extract Raw Chunks of data from identifiable ELF Sections

use MooseX::Declare;

class ELF::Extract::Sections with MooseX::Log::Log4perl {

=head1 CAVEATS

=over 4

=item 1. Beta Software

This code is relatively new. It exists only as a best attempt at present until further notice. It
has proved as practical for at least one application, and this is why the module exists. However, it can't be
guaranteed it will work for whatever you want it to in all cases. Please report any bugs you find.

=item 2. Feature Incomplete

This only presently has a very bare-bones functionality, which should however prove practical for most purposes.
If you have any suggestions, please tell me via "report bugs". If you never seek, you'll never find.

=item 3. Humans

This code is written by a human, and like all human code, it sucks. There will be bugs. Please report them.

=back

=head1 SYNOPSIS

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

=cut

    use MooseX::Has::Sugar 0.0300;
    use MooseX::Types::Moose                ( ':all', );
    use MooseX::Types::Path::Tiny           ( 'File', );
    use ELF::Extract::Sections::Meta::Types ( ':all', );
    use Class::Load                         ( 'try_load_class', );

    require ELF::Extract::Sections::Section;

=head1 PUBLIC ATTRIBUTES
=cut

=head2 -> file

Returns the file the section data is being created for.

=cut

    has 'file' => ( isa => File, ro, required, coerce, );

=head2 -> sections

Returns a HashRef of the available sections.

=cut

    has 'sections' => ( isa => HashRef [ElfSection], ro, lazy_build, );

=head2 -> scanner

Returns the name of the default scanner plug-in

=cut

    has 'scanner' => ( isa => Str, ro, default => 'Objdump', );

=head1 PUBLIC METHODS

=cut

=head2 -> new ( file => FILENAME )

=head2 -> new ( file => FILENAME , scanner => 'Objdump' )

Creates A new Section Extractor object

=cut

    method BUILD ( $args ) {
        if ( not $self->file->stat ) {
            $self->log->logconfess(q{File Specifed could not be found.});
        }
    }

=head2 -> sorted_sections ( field => SORT_BY )

=head2 -> sorted_sections ( field => SORT_BY, descending => DESCENDING )

Returns an ArrayRef sorted by the SORT_BY field. May be Ascending or Descending depending on requirements.

=head3 DESCENDING

Optional parameters. True for descending, False or absent for ascending.

=head3 SORT_BY

A String of the field to sort by. Valid options at present are

=head4 name

The Section Name

=head4 offset

The Sections offset relative to the start of the file.

=head4 size

The Size of the section.

=cut

    method sorted_sections (  FilterField :$field!, Bool :$descending? ) {
        my $m = 1;
        $m = 0 - 1 if ($descending);
        return [ sort { $m * ( $a->compare( other => $b, field => $field ) ) }
              values %{ $self->sections } ];
    }

=head1 PUBLIC ATTRIBUTE BUILDERS

These aren't really user serviceable, but they make your front end work.

=cut

=head2 -> _build_sections

=cut

    method _build_sections {
        $self->log->debug('Building Section List');
        if ( $self->_scanner_instance->can_compute_size ) {
            return $self->_scan_with_size;
        }
        else {
            return $self->_scan_guess_size;
        }
    }

=head1 PRIVATE ATTRIBUTES
=cut

=head2 -> _scanner_package
=cut

    has '_scanner_package' => ( isa => ClassName, ro, lazy_build, );

=head2 -> _scanner_instance
=cut

    has '_scanner_instance' => ( isa => Object, ro, lazy_build, );

=head1 PRIVATE ATTRIBUTE BUILDERS
=cut

=head2 _build__scanner_package
=cut

    method _error_scanner_missing ( Str $scanner!, Str $package!, Str $error! ) {
        my $message = sprintf qq[The Scanner %s could not be found as %s\n.],
          $scanner, $package;
        $message .= '>' . $error;
        $self->log->logconfess($message);
    }

    method _build__scanner_package {
        my $pkg = 'ELF::Extract::Sections::Scanner::' . $self->scanner;
        my ( $success, $error ) = try_load_class($pkg);
        if ( not $success ) {
            $self->_error_scanner_missing( $self->scanner, $pkg, $error );
        }
        return $pkg;
    }

=head2 -> _build__scanner_instance
=cut

    method _build__scanner_instance {
        my $instance = $self->_scanner_package->new();
        return $instance;
    }

=head1 PRIVATE_METHODS
=cut

=head2 -> _stash_record( HashRef, Str, Str )
=cut

    method _warn_stash_collision ( Str $stashname!, Str $header!, Str $offset! ) {
        my $message = qq[Warning, duplicate file offset reported by scanner.];
        $message .= sprintf qq[<%s> and <%s> collide at <%s>.], $stashname,
          $header, $offset;
        $message .= sprintf qq[Assuming <%s> is empty and replacing it.],
          $stashname;
        $self->log->warn($message);
    }

    method _stash_record ( HashRef $stash! , Str $header!, Str $offset! ) {
        if ( exists $stash->{$offset} ) {
            $self->_warn_stash_collision( $stash->{$offset}, $header, $offset );
        }
        $stash->{$offset} = $header;
    }

=head2 -> _build_section_section( Str, Int, Int, File )
=cut

    method _build_section_section ( Str $stashName, Int $start, Int $stop , File $file ) {
        $self->log->info(" Section ${stashName} , ${start} -> ${stop} ");
        return ELF::Extract::Sections::Section->new(
            offset => $start,
            size   => $stop - $start,
            name   => $stashName,
            source => $file,
        );
    }

=head2 -> _build_section_table( HashRef )
=cut

    method _build_section_table ( HashRef $ob! ) {
        my %datastash = ();
        my @k         = sort { $a <=> $b } keys %{$ob};
        my $i         = 0;
        while ( $i < $#k ) {
            $datastash{ $ob->{ $k[$i] } } = $self->_build_section_section(
                $ob->{ $k[$i] },
                $k[$i], $k[ $i + 1 ],
                $self->file
            );
            $i++;
        }
        return \%datastash;
    }

=head2 -> _scan_guess_size
=cut

    method _scan_guess_size {
                              # HACK: Temporary hack around rt#67210
        scalar $self->_scanner_instance->open_file( file => $self->file );
        my %offsets = ();
        while ( $self->_scanner_instance->next_section() ) {
            my $name   = $self->_scanner_instance->section_name;
            my $offset = $self->_scanner_instance->section_offset;
            $self->_stash_record( \%offsets, $name, $offset );
        }
        return $self->_build_section_table( \%offsets );
    }

=head2 -> _scan_with_size
=cut

    method _scan_with_size {
        my %datastash = ();
        $self->_scanner_instance->open_file( file => $self->file );
        while ( $self->_scanner_instance->next_section() ) {
            my $name   = $self->_scanner_instance->section_name;
            my $offset = $self->_scanner_instance->section_offset;
            my $size   = $self->_scanner_instance->section_size;
            $datastash{$name} =
              $self->_build_section_section( $name, $offset, $offset + $size,
                $self->file );
        }
        return \%datastash;
    }

};

1;

__END__


=head1 DEBUGGING

This library uses L<Log::Log4perl>. To see more verbose processing notices, do this:

    use Log::Log4perl qw( :easy );
    Log::Log4perl->easy_init($DEBUG);

For convenience to make sure you don't happen to miss this fact, we never initialize Log4perl ourselves, so it will
spit the following message if you have not set it up:

    Log4perl: Seems like no initialization happened. Forgot to call init()?

To suppress this, just do

    use Log::Log4perl qw( :easy );

I request however you B<don't> do that for modules intended to be consumed by others without good cause.

=head1 ACKNOWLEDGEMENTS

=cut

