use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name        => 'Telnet::Parse',
    license            => 'perl',
    dist_author        => 'Troels Liebe Bentsen <troels@infopro.dk>',
    dist_version_from  => 'lib/Telnet/Parse.pm',
    create_readme      => 1,
    create_makefile_pl => 'passthrough',
    requires => {
        'perl' => '>= 5.8.0',
        'Carp' => 0,
        'Exporter' => 0,
    },
    build_requires => {
        'Test::More' => 0,
    },
    add_to_cleanup => [ 
        'Telnet-Parse-*',
        'Makefile',
        'blib',
    ],
);

$builder->create_build_script();
