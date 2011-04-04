
use strict;
use warnings;

use Module::Build 0.3601;


my %module_build_args = (
  'build_requires' => {
    'English' => '0',
    'File::Find' => '0',
    'File::Find::Rule' => '0',
    'File::Temp' => '0',
    'FindBin' => '0',
    'Log::Log4perl' => '0',
    'Module::Build' => '0.3601',
    'Path::Class' => '0',
    'Test::More' => '0.88',
    'YAML::XS' => '0'
  },
  'configure_requires' => {
    'Module::Build' => '0.3601'
  },
  'dist_abstract' => 'Extract Raw Chunks of data from identifiable ELF Sections',
  'dist_author' => [
    'Kent Fredric <kentnl@cpan.org>'
  ],
  'dist_name' => 'ELF-Extract-Sections',
  'dist_version' => '0.02071411',
  'license' => 'perl',
  'module_name' => 'ELF::Extract::Sections',
  'recommends' => {},
  'recursive_test_files' => 1,
  'requires' => {
    'Class::Load' => '0',
    'Log::Log4perl' => '1.21',
    'Moose' => '0.76',
    'MooseX::Declare' => '0.20',
    'MooseX::Has::Sugar' => '0.0300',
    'MooseX::Log::Log4perl' => '0.31',
    'MooseX::Types' => '0.10',
    'MooseX::Types::Moose' => '0.10',
    'MooseX::Types::Path::Class' => '0.05',
    'overload' => '0',
    'perl' => '5.010000'
  },
  'script_files' => []
);


my $build = Module::Build->new(%module_build_args);

$build->create_build_script;
