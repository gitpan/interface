package MyTestModule;

use warnings FATAL => qw( prototype );

use    interface MyInterface;

sub foo {
    warn "Foo!\n";
}

sub bar ($@) {
    warn "Bar!\n";
}

#sub foo($);
#
#sub bar($@);

1;
