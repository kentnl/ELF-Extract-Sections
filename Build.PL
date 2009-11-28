
use strict;
use warnings;

use Module::Build;

my $build = Module::Build->new(
  module_name   => 'ELF::Extract::Sections',
  license       => 'perl',
  dist_abstract => "Extract\ Raw\ Chunks\ of\ data\ from\ identifiable\ ELF\ Sections",
  dist_name     => "ELF\-Extract\-Sections",
  dist_author   => [
"Kent\ Fredric\ \<kentnl\@cpan\.org\>",
  ],
  requires      => {
    "MooseX::Has::Sugar" => '0.0300',
    "MooseX::Types::Moose" => '0.10',
    "MooseX::Declare" => '0.20',
    "FindBin" => '0',
    "YAML::XS" => '0',
    "lib" => '0',
    "MooseX::Log::Log4perl" => '0.31',
    "Moose" => '0.76',
    "Moose::Role" => '0',
    "File::Find::Rule" => '0',
    "overload" => '0',
    "perl" => '5.010000',
    "Test::More" => '0',
    "MooseX::Types::Path::Class" => '0.05',
    "MooseX::Types" => '0.10',
    "Path::Class" => '0',
    "Log::Log4perl" => '1.21',
  },
  script_files => [ qw() ],
);

$build->create_build_script;
