use Test::More;

plan tests => 1;

eval "use interface;";

my $e = $@;
diag($e) if $e;

ok(!$e);

exit 0;
