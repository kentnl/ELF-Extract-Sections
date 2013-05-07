
use strict;
use warnings;

use Module::Build 0.3601;


my %module_build_args = (
  "build_requires" => {
    "Module::Build" => "0.4004"
  },
  "configure_requires" => {
    "Module::Build" => "0.4004"
  },
  "dist_abstract" => "Extract Raw Chunks of data from identifiable ELF Sections",
  "dist_author" => [
    "Kent Fredric <kentnl\@cpan.org>"
  ],
  "dist_name" => "ELF-Extract-Sections",
  "dist_version" => "0.02071412",
  "license" => "perl",
  "module_name" => "ELF::Extract::Sections",
  "recommends" => {},
  "recursive_test_files" => 1,
  "requires" => {
    "Class::Load" => 0,
    "Log::Log4perl" => "1.21",
    "Moose" => "0.76",
    "MooseX::Declare" => "0.20",
    "MooseX::Has::Sugar" => "0.0300",
    "MooseX::Log::Log4perl" => "0.31",
    "MooseX::Types" => "0.10",
    "MooseX::Types::Moose" => "0.10",
    "MooseX::Types::Path::Class" => "0.05",
    "MooseX::Types::Path::Tiny" => 0,
    "overload" => 0,
    "perl" => "5.010000",
    "strict" => 0,
    "warnings" => 0
  },
  "script_files" => [],
  "test_requires" => {
    "File::Find" => 0,
    "File::Find::Rule" => 0,
    "File::Temp" => 0,
    "FindBin" => 0,
    "Log::Log4perl" => 0,
    "Path::Class" => 0,
    "Test::More" => "0.98",
    "YAML::XS" => 0
  }
);


unless ( eval { Module::Build->VERSION(0.4004) } ) {
  my $tr = delete $module_build_args{test_requires};
  my $br = $module_build_args{build_requires};
  for my $mod ( keys %$tr ) {
    if ( exists $br->{$mod} ) {
      $br->{$mod} = $tr->{$mod} if $tr->{$mod} > $br->{$mod};
    }
    else {
      $br->{$mod} = $tr->{$mod};
    }
  }
}

my $build = Module::Build->new(%module_build_args);

$build->create_build_script;
