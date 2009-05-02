use inc::Module::Install;

name     'ELF-Extract-Sections';
all_from 'lib/ELF/Extract/Sections.pm';
author   'Kent Fredric <kentfredric@gmail.com>';
license  'perl';

build_requires 'Test::More';

auto_install;

WriteAll;

