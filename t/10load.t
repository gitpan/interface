use Test::More;

plan tests => 1;

push @INC, 't/lib';

eval "use interface MyInterface;";

my $e = $@;
diag($e) if $e;

ok(!$e);

exit 0;
