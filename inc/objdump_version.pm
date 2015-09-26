use 5.006;    # our
use strict;
use warnings;

package objdump_version;

# ABSTRACT: Detect a supported objdump version

# AUTHORITY

our %KNOWN_BAD = (
    linux       => [ q[GNU objdump (GNU Binutils for Raspbian) 2.25.1], q[GNU objdump 2.17 Debian GNU/Linux], ],
    gnukfreebsd => [],
    freebsd     => [ q[GNU objdump 2.17.50 [FreeBSD] 2007-07-03], ],
    openbsd     => [ q[GNU objdump 2.15], ],
);
our %KNOWN_GOOD = (
    linux => [
        q[GNU objdump (GNU Binutils for Debian) 2.25],
        q[GNU objdump (GNU Binutils for Debian) 2.25.1],
        q[GNU objdump (GNU Binutils for Debian) 2.22],
        q[GNU objdump version 2.23.52.0.1-30.el7_1.2 20130226],
    ],
    gnukfreebsd =>
      [ q[GNU objdump (GNU Binutils for Debian) 2.20.1-system.20100303], q[GNU objdump (GNU Binutils for Debian) 2.25], ],
    freebsd   => [ q[GNU objdump (GNU Binutils) 2.25], ],
    dragonfly => [ q[GNU objdump (GNU Binutils) 2.24], ],
    cygwin    => [ q[GNU objdump (GNU Binutils) 2.25], ],
);

use Term::ANSIColor qw( colored );
use File::Which qw( which );
use Capture::Tiny qw( capture );

my @state = ();

sub record_state {
  push @state, $_[0];
  open my $fh, '>' , 't/_objdump_version' or return;
  print $fh "$_\n" for @state;
  close $fh;
  return;
}

sub is_na {
    if ( not $ENV{FORCE_BAD_OBJDUMP} ) {
        bad_msg( $_[0] );
        bad_msg("Please install a recent GNU objdump and try again.\n");
        bad_msg("Or Set FORCE_BAD_OBJDUMP to override this check.\n");
        print STDERR "NA: Unable to build distribution on this platform.\n";
        exit(0);
    }
    record_state('forced');
    warn_msg( $_[0] );
    warn_msg("FORCE_BAD_OBJDUMP overriding failure.\n");
    return 0;
}

sub good_msg {
    print STDERR colored( $_[0], 'bright_green' );
    return 1;
}
sub quote_msg {
    my @lines = split /\n/, $_[0];
    for my $line ( @lines ) {
      print STDERR colored( "> ", 'bright_white' );
      print STDERR "$line\n";
    }
}

sub bad_msg {
    print STDERR colored( $_[0], 'bright_red' );
    return 0;
}

sub warn_msg {
    print STDERR colored( $_[0], 'bright_yellow' );
}

sub version_check {
    my $path = which('objdump');
    if ( not $path ) {
        record_state('no_binary');
        return is_na("No 'objdump' binary.\n");
    }
    my ( $stdout, $stderr, $exit ) = capture { system("objdump --version") };
    if ( $exit != 0 ) {
        record_state('exit_nonzero');
        return is_na( "'objdump' binary responded with exit code other than 0.\n" . "Broken/Old/Non-GNU `objdump` binary.\n" );
    }
    for my $bad_string ( @{ $KNOWN_BAD{$^O} || [] } ) {
        next unless $stdout =~ /(?:\A|(?<=\n))\Q$bad_string\E/;
        record_state('known_bad');
        return is_na(
            "'objdump' binary responded with a known-bad version $bad_string.\n" . "Broken/Old/Non-GNU `objdump` binary.\n" );
    }
    for my $good_string ( @{ $KNOWN_GOOD{$^O} || [] } ) {
        next unless $stdout =~ /(?:\A|(?<=\n))\Q$good_string\E/;
        record_state('known_good');
        good_msg("Known Good obdump: $good_string");
        return 1;
    }
    record_state('unknown');
    warn_msg("Unknown objdump version string, proceed with caution\n");
    quote_msg($stdout);
    return 1;
}
1;

