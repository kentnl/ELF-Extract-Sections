use inc::Module::Install;

name 'ELF-Extract-Sections';
all_from 'lib/ELF/Extract/Sections.pm';
author 'Kent Fredric <kentfredric@gmail.com>';
license 'perl';

repository 'git://github.com/kentfredric/ELF-Extract-Sections.git';

requires 'Moose'                      => '0.76';
requires 'namespace::clean'           => '0.11';
requires 'Log::Log4perl'              => '1.21';
requires 'MooseX::Log::Log4perl'      => '0.31';
requires 'Moose::Role'                => '0.00';
requires 'MooseX::Declare'            => '0.20';
requires 'MooseX::Types::Moose'       => '0.10';
requires 'MooseX::Types::Path::Class' => '0.05';

test_requires 'Test::More';

recommends 'FindBin';
recommends 'lib';

requires_external_bin 'objdump';  # This should be available as part of BinUtils

auto_install;

WriteAll;

