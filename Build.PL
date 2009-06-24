use strict;
use warnings;

use lib 'inc';

use Module::Build;
use MyBuilder;

my $builder = MyBuilder->new(
  module_name       => 'interface',
  license           => 'perl',
  dist_author       => 'Andy Armstrong <andy@hexten.net>',
  dist_version_from => 'lib/interface.pm',
  requires          => {
    'Test::More' => 0,
    'latest'     => '0.02',
  },
  add_to_cleanup => ['interface-*'],
);

$builder->create_build_script();
