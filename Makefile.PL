
use strict;
use warnings;

use ExtUtils::MakeMaker;

WriteMakefile(
  DISTNAME  => 'ELF-Extract-Sections',
  NAME      => 'ELF::Extract::Sections',
  AUTHOR    => 'Kent\ Fredric\ \<kentnl\@cpan\.org\>',
  ABSTRACT  => 'Extract\ Raw\ Chunks\ of\ data\ from\ identifiable\ ELF\ Sections',
  VERSION   => '0.0104',
  EXE_FILES => [ qw() ],
  (eval { ExtUtils::MakeMaker->VERSION(6.31) } ? (LICENSE => 'perl') : ()),
  PREREQ_PM    => {
    "MooseX::Types::Moose" => '0.10',
    "MooseX::Has::Sugar" => '0.0300',
    "MooseX::Declare" => '0.20',
    "FindBin" => '0',
    "YAML::XS" => '0',
    "lib" => '0',
    "MooseX::Log::Log4perl" => '0.31',
    "Moose" => '0.76',
    "Moose::Role" => '0',
    "File::Find::Rule" => '0',
    "overload" => '0',
    "Test::More" => '0',
    "MooseX::Types::Path::Class" => '0.05',
    "MooseX::Types" => '0',
    "Path::Class" => '0',
    "Log::Log4perl" => '1.21',
  },
);
