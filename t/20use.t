use Test::More;

plan tests => 1;

push @INC, 't/lib';

eval "use MyBrokenModule;";

my $e = $@;
diag($e) unless $e =~ m{Prototype mismatch: sub MyTestModule::foo \(\$\) vs none} ;

ok($e =~ m{Prototype mismatch: sub MyTestModule::foo \(\$\) vs none});

exit 0;
