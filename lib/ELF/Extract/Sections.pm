use 5.006;
use strict;
use warnings;

package ELF::Extract::Sections;

# ABSTRACT: Extract Raw Chunks of data from identifiable ELF Sections

our $VERSION = '1.000001';

# AUTHORITY

use Moose qw( with has );
use Carp qw( croak );
with 'MooseX::Log::Log4perl';

use MooseX::Has::Sugar 0.0300;
use MooseX::Types::Moose                ( ':all', );
use MooseX::Types::Path::Tiny           ( 'File', );
use ELF::Extract::Sections::Meta::Types ( ':all', );
use Module::Runtime                     ( 'require_module', );

require ELF::Extract::Sections::Section;

=head1 PUBLIC ATTRIBUTES
=cut

=head2 file

Returns the file the section data is being created for.

=cut

has 'file' => ( isa => File, ro, required, coerce, );

=head2 sections

Returns a HashRef of the available sections.

=cut

has 'sections' => ( isa => HashRef [ElfSection], ro, lazy_build, );

=head2 scanner

Returns the name of the default scanner plug-in

=cut

has 'scanner' => ( isa => Str, ro, default => 'Objdump', );

=head1 PUBLIC METHODS

=cut

=head2 new ( file => FILENAME )

Creates A new Section Extractor object with the default scanner

=head2 new ( file => FILENAME , scanner => 'Objdump' )

Creates A new Section Extractor object with the specified scanner

=cut

=for Pod::Coverage BUILD

=cut

sub BUILD {
    my ( $self, ) = @_;
    if ( not $self->file->stat ) {
        $self->log->logconfess(q{File Specifed could not be found.});
    }
    return;
}

=head2 sorted_sections ( field => SORT_BY )

Returns an ArrayRef sorted by the SORT_BY field, in the default order.

=head2 sorted_sections ( field => SORT_BY, descending => DESCENDING )

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

sub _argument {
    my ( $args, $number, $type, %flags ) = @_;
    return if not $flags{required} and @{$args} < $number + 1;
    my $can_coerce = $flags{coerce} ? '(coerceable)' : q[];

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
    my $can_coerce = $flags{coerce} ? '(coerceable)' : q[];
    exists $args->{$name} or croak "Parameter '$name' of type $type$can_coerce was not specified";

    if ( not $flags{coerce} ) {
        $type->check( $args->{$name} ) and return delete $args->{$name};
    }
    else {
        my $value = $type->coerce( delete $args->{$name} );
        return $value if $value;
    }
    return croak "Parameter '$name' was not of type $type$can_coerce: " . $type->get_message( $args->{$name} );
}

sub sorted_sections {
    my ( $self, %args ) = @_;
    my $field      = _parameter( \%args, 'field',      FilterField, required => 0 );
    my $descending = _parameter( \%args, 'descending', Bool,        required => 0 );
    if ( keys %args ) {
        croak "Unknown parameters @{[ keys %args ]}";
    }
    my $m = 1;
    $m = 0 - 1 if ($descending);
    return [ sort { $m * ( $a->compare( other => $b, field => $field ) ) } values %{ $self->sections } ];
}

sub _build_sections {
    my ($self) = @_;
    $self->log->debug('Building Section List');
    if ( $self->_scanner_instance->can_compute_size ) {
        return $self->_scan_with_size;
    }
    else {
        return $self->_scan_guess_size;
    }
}

has '_scanner_package' => ( isa => ClassName, ro, lazy_build, );

has '_scanner_instance' => ( isa => Object, ro, lazy_build, );

__PACKAGE__->meta->make_immutable;
no Moose;

sub _error_scanner_missing {
    my ( $self, @args ) = @_;
    @args < 4 or croak 'Too many arguments';
    my $scanner = _argument( \@args, 0, Str, required => 1 );
    my $package = _argument( \@args, 1, Str, required => 1 );
    my $error   = _argument( \@args, 2, Str, required => 1 );
    my $message = sprintf qq[The Scanner %s could not be found as %s\n.], $scanner, $package;
    $message .= '>' . $error;
    $self->log->logconfess($message);
    return;
}

sub _build__scanner_package {
    my ($self) = @_;
    my $pkg = 'ELF::Extract::Sections::Scanner::' . $self->scanner;
    local $@ = undef;
    if ( not eval { require_module($pkg); 1 } ) {
        return $self->_error_scanner_missing( $self->scanner, $pkg, $@ );
    }
    return $pkg;
}

sub _build__scanner_instance {
    my ($self) = @_;
    my $instance = $self->_scanner_package->new();
    return $instance;
}

sub _warn_stash_collision {
    my ( $self, @args ) = @_;
    @args < 4 or croak 'Too many arguments';
    my $stashname = _argument( \@args, 0, Str, required => 1 );
    my $header    = _argument( \@args, 1, Str, required => 1 );
    my $offset    = _argument( \@args, 2, Str, required => 1 );

    my $message = q[Warning, duplicate file offset reported by scanner.];
    $message .= sprintf q[<%s> and <%s> collide at <%s>.], $stashname, $header, $offset;
    $message .= sprintf q[Assuming <%s> is empty and replacing it.], $stashname;
    $self->log->warn($message);
    return;
}

sub _stash_record {
    my ( $self, @args ) = @_;
    @args < 4 or croak 'Too many arguments';
    my $stash  = _argument( \@args, 0, HashRef, required => 1 );
    my $header = _argument( \@args, 1, Str,     required => 1 );
    my $offset = _argument( \@args, 2, Str,     required => 1 );

    if ( exists $stash->{$offset} ) {
        $self->_warn_stash_collision( $stash->{$offset}, $header, $offset );
    }
    $stash->{$offset} = $header;
    return;
}

sub _build_section_section {
    my ( $self, @args ) = @_;
    @args < 5 or croak 'Too many arguments';
    my $stashName = _argument( \@args, 0, Str,  required => 1 );
    my $start     = _argument( \@args, 1, Int,  required => 1 );
    my $stop      = _argument( \@args, 2, Int,  required => 1 );
    my $file      = _argument( \@args, 3, File, required => 1 );

    $self->log->info(" Section ${stashName} , ${start} -> ${stop} ");
    return ELF::Extract::Sections::Section->new(
        offset => $start,
        size   => $stop - $start,
        name   => $stashName,
        source => $file,
    );
}

sub _build_section_table {
    my ( $self, @args ) = @_;
    @args < 2 or croak 'Too many arguments';
    my $ob        = _argument( \@args, 0, HashRef, required => 1 );
    my %datastash = ();
    my @k         = sort { $a <=> $b } keys %{$ob};
    my $i         = 0;
    while ( $i < $#k ) {
        $datastash{ $ob->{ $k[$i] } } = $self->_build_section_section( $ob->{ $k[$i] }, $k[$i], $k[ $i + 1 ], $self->file );
        $i++;
    }
    return \%datastash;
}

sub _scan_guess_size {
    my ($self) = @_;

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

sub _scan_with_size {
    my ($self) = @_;
    my %datastash = ();
    $self->_scanner_instance->open_file( file => $self->file );
    while ( $self->_scanner_instance->next_section() ) {
        my $name   = $self->_scanner_instance->section_name;
        my $offset = $self->_scanner_instance->section_offset;
        my $size   = $self->_scanner_instance->section_size;
        $datastash{$name} = $self->_build_section_section( $name, $offset, $offset + $size, $self->file );
    }
    return \%datastash;
}

1;

__END__

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

=cut

