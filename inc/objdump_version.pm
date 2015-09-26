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

sub is_na {
    if ( not $ENV{FORCE_BAD_OBJDUMP} ) {
        bad_msg( $_[0] );
        bad_msg("Please install a recent GNU objdump and try again.\n");
        bad_msg("Or Set FORCE_BAD_OBJDUMP to override this check.\n");
        print STDERR "NA: Unable to build distribution on this platform.\n";
        exit(0);
    }
    warn_msg( $_[0] );
    warn_msg("FORCE_BAD_OBJDUMP overriding failure.\n");
    return 0;
}

sub good_msg {
    print STDERR colored( $_[0], 'bright_green' );
    return 1;
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
        return is_na("No 'objdump' binary.\n");
    }
    my ( $stdout, $stderr, $exit ) = capture { system("objdump --version") };
    if ( $exit != 0 ) {
        return is_na( "'objdump' binary responded with exit code other than 0.\n" . "Broken/Old/Non-GNU `objdump` binary.\n" );
    }
    for my $bad_string ( @{ $KNOWN_BAD{$^O} || [] } ) {
        next unless $stdout =~ /(?:\A|(?<=\n))\Q$bad_string\E/;
        return is_na(
            "'objdump' binary responded with a known-bad version $bad_string.\n" . "Broken/Old/Non-GNU `objdump` binary.\n" );
    }
    for my $good_string ( @{ $KNOWN_GOOD{$^O} || [] } ) {
        next unless $stdout =~ /(?:\A|(?<=\n))\Q$good_string\E/;
        good_msg("Known Good obdump: $good_string");
        return 1;
    }
    warn_msg("Unknown objdump version string, proceed with caution");
    print STDERR $stdout;
    return 1;
}
1;

