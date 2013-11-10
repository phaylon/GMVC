use strict;
use warnings FATAL => 'all';
use ExtUtils::MakeMaker;

(do 'maint/Makefile.PL.include' or die $@) unless -f 'META.yml';

my %_deps_runtime = (
    'aliased' => 0,
    'Config::Rad' => 0,
    'curry::weak' => 0,
    'Module::Runtime' => '0.013',
    'namespace::clean' => 0,
    'Object::Glib' => 0,
    'Path::Tiny' => 0,
    'strictures' => 0,
);

my %_deps_tests = (
);

WriteMakefile(
  NAME => 'GMVC',
  VERSION_FROM => 'lib/GMVC.pm',
  PREREQ_PM => { %_deps_runtime },
  BUILD_REQUIRES => { %_deps_tests },
  LICENSE => 'perl',
);
