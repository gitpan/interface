package MyTestModule::Two;

sub foo ($) { }

sub bar ($@) { }

sub this ($@) {}

sub that(\$@) { }

sub foobar { }

package MyTestModule::Three;

our @ISA = qw(MyTestModule);

package MyTestModule::Four;

our @ISA = qw(MyTestModule::Two);

package MyTestModule;

use interface qw(MyInterface);

sub this($@) {}

sub that(\$@) { }

sub foo ($) { }

sub bar ($@) { }

sub foobar { }

1;
