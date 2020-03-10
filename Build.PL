use 5.006;
use strict;
use warnings;
use Module::Build;
Module::Build->VERSION('0.4004');

my $builder = Module::Build->new(
    module_name         => 'Trello',
    license             => 'artistic_2',
    dist_author         => q{Pablo Alvarez de Sotomayor <pablo.alvarez@lana.xyz>},
    dist_version_from   => 'lib/Trello.pm',
    release_status      => 'stable',
    configure_requires => {
        'Module::Build' => '0.4004',
    },
    test_requires => {
        'Test::More' => '0',
    },
    requires => {
		'IO::Socket::SSL' => '2.067',
		'JSON' => '4.02',
		'Moose' => '2.2012',
		'Role::REST::Client' => '0.23',
		'URI::Escape' => '3.31',
    },
    add_to_cleanup     => [ 'Trello-*' ],
);

$builder->create_build_script();
