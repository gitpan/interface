use Test::More;

plan tests => 5;

push @INC, 't/lib';

eval "use MyTestModule;";

my $e = $@;
diag($e) if $e;

ok(!$e);

ok('MyTestModule::Three' -> implements('MyInterface'));

ok('MyTestModule::Four' -> implements('MyInterface'));

ok('MyTestModule' -> implements('MyInterface'));

ok('MyTestModule::Two' -> implements('MyInterface'));

exit 0;
