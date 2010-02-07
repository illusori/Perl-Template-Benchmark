#!/usr/bin/perl -w

use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'Template::Benchmark',
    license             => 'perl',
    dist_author         => q{Sam Graham <libtemplate-benchmark-perl@illusori.co.uk>},
    dist_version_from   => 'lib/Template/Benchmark.pm',
    build_requires => {
        'Test::More'        => 0,
        'Module::Build'     => 0.07,
    },
    requires => {
        #  For the module.
        'Module::Pluggable'         => 0,
        'Benchmark'                 => 0,
        'POSIX'                     => 0,
        'File::Path'                => 0,
        'File::Spec'                => 0,
        'IO::File'                  => 0,
        #  For the script.
        'FindBin'                   => 0,
        'Getopt::Long'              => 0,
        'Pod::Usage'                => 0,
        'Text::Wrap'                => 0,
    },
    sign => 1,
    dynamic_config => 0,
    create_makefile_pl => 'passthrough',
);

$builder->create_build_script();
