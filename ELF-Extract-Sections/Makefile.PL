use inc::Module::Install;

name 'ELF-Extract-Sections';
all_from 'lib/ELF/Extract/Sections.pm';
author 'Kent Fredric <kentfredric@gmail.com>';
license 'perl';

repository 'git://github.com/kentfredric/ELF-Extract-Sections.git';

build_requires 'Module::Install';

test_requires 'Test::More';

requires_external_bin 'objdump';  # This should be available as part of BinUtils

auto_install;

WriteAll;

