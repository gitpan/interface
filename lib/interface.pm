package interface;

use Filter::Simple;
use Carp;

use strict;

our $VERSION = '0.01';

my %SIGNATURES;
my %SANSSIGS;

sub _require ($);

FILTER_ONLY
    code => sub {
        # filter the parts between `interface <something>' and `interface|package'
        return unless $_;

        my(@interfaces);
        my @p;

        #(?:\A|egakcap|locotorp(?!\s+esu\b))(?:\s|\A)( (?:.|\n)*? \s+ locotorp(?!\s+esu\b))\s*

#        if(0) {
#        (@interfaces)= m{\s*
#                        (
#                            interface \s+
#                            (?:.|\n)*?
#                        )
#                        (?:\s|\Z)
#                        (?=
#                            (?<! use\s)interface
#                          | package
#                          | \Z
#                        )
#                       }gmx;
#
#        s{\s*
#          (
#              interface \s+
#              (?:.|\n)*?
#          )
#          (?=
#              interface
#            | package
#            | \Z
#          )
#          }{1;}gmx;
#        }
#        else {  # this version is reversed since variable-length negative 
                # lookbehinds are not allowed - should be equivalent to first 
                # block above
            $_ = reverse;
            (@interfaces) = m{(?: \A
                               | egakcap
                               | ecafretni (?! \s+ esu \b )
                             )
                             (?: \s
                               | \A
                             )
                             ( 
                                 (?:.|\n)*? 
                                 \s+ ecafretni (?! \s+ esu \b )
                             )
                             \s*
                            }gmx;
             s{(?: \A
                 | egakcap
                 | ecafretni (?! \s+ esu \b )
               )
               (?: \s
                 | \A
               )
               (
                   (?:.|\n)*? 
                   \s+ ecafretni (?! \s+ esu \b )    
               )   
               \s*
              }{;1}gmx;

              $_ = reverse;
              $_ = reverse foreach @interfaces;
#         }
          

        foreach my $interface (reverse @interfaces) {
            local($_);
            no strict 'refs';

            # need to figure out how to dig ourselves out and give better error messages
            carp "Syntax error in interface declaration" unless $interface =~ m{^interface\s+(\S*?)\s*;\s*};
            my $interface_name = $1;

            my(@used_interfaces) = $interface =~ m{use\s+interface\s+((?:.|\n)*?);}mg;

            my(%lines) = $interface =~ m{sub\s+([^\s\(]+)\s*\(((?:.|\n)*?)\)\s*;}mg;
            my(@prototypeless) = $interface =~ m{sub\s+([^\s\(]+)\s*;}mg;

            my $p;
            foreach $p (@used_interfaces) {
                eval qq{ 
                    package $interface_name; 
                    interface::_require \$p;
                };
                croak $@ if $@;
                push @{$interface_name . "::INTERFACES"}, $p;
                @{$SIGNATURES{$interface_name}}{keys %{$SIGNATURES{$p}}} = values %{$SIGNATURES{$p}};
                @{$SANSSIGS{$interface_name}}{keys %{$SANSSIGS{$p}}} = values %{$SANSSIGS{$p}};
            }

            @{$SIGNATURES{$interface_name}}{keys %lines} = values %lines;
            @{$SANSSIGS{$interface_name}}{@prototypeless} = (undef) x @prototypeless;
            #foreach my $k (keys %{$SIGNATURES{$interface_name}}) {
                #warn "  $k => $SIGNATURES{$interface_name}{$k}\n";
            #}
            #warn "without sigs: ", join(", ", @prototypeless), "\n";
        }
        #warn "Done looking at interfaces\n";
    },
;



# a source filter, basically (for the interface definition part)
sub import {
    shift;
    my $parent = caller;

    if(@_) {
        # need to import each interface package and modify @INTERFACES
        no strict 'refs';
        foreach my $class (@_) {
            #eval "require $class;";
            _require $class;
            #carp "$@\n" if $@;
            push @{caller() . "::INTERFACES"}, $class;
            my($sub, $sig);
            while(($sub, $sig) = each %{$SIGNATURES{$class}}) {
                eval "sub ${parent}::${sub} ($sig);";
                carp $@ if $@;
            }
        }
    }
}

my %INTERFACES;

sub UNIVERSAL::implements {
    my $class = shift;
    my $interface = shift;

    return 1 if $INTERFACES{$class}{$interface};

    return if $class eq $interface;

    # need to trace @ISA and @INTERFACES (and @INTERFACES of each in the @ISA chain)
    no strict 'refs';
    foreach my $p ( @{$class . "::INTERFACES"}, @{$class . "::ISA"} ) {
        return $INTERFACES{$class}{$interface} = 1 if $p -> implements($interface);
    }

    # we get here if we don't explicitely follow the interface
    # check what the class implements and what the prototype is
    unless(exists($SIGNATURES{$interface}) || exists($SANSSIGS{$interface})) {
        eval "use interface $interface;";
    };
    
    my($sub, $sig, $method);
    while(($sub, $sig) = each %{$SIGNATURES{$interface}}) {
        my $method = $class -> can($sub);
#        warn "$class -> $sub => $method\n";
        return 0 unless $method;
#        warn "    prototype: ", prototype($method), "\n";
        return 0 unless prototype($method) eq $sig;
    }
    foreach my $sub (keys %{$SANSSIGS{$interface}}) {
        #my $method = $class -> can($sub);
        #warn "$class -> $sub => $method\n";
        return 0 unless $class -> can($sub);
    }

    return $INTERFACES{$class}{$interface} = 1;
}

sub _require ($) {
    my $interface = shift;

    my $file = $interface;
    $file =~ s{::}{/};
    eval "require q{\Q$file\E.pi};";
    if($@) {
        eval "require $interface";
        carp $@ if $@;
    }
}

1;

__END__

=head1 NAME

interface - Define an API for use by a package

=head1 SYNOPSIS

Define an interface:

 use interface;

 interface My::API;

 use interface qw(My::Other::API);

 sub foo ($);
 sub bar ($@);


Use an interface:

 package My::Implementation;

 use interface qw(My::API);


Other methods:

 UNIVERSAL::implements( My::Implementation => 'My::API' );

=head1 DESCRIPTION

This package introduces a new Perl keyword, C<interface>, that allows 
API declarations via subroutine prototypes.

Usually, an algorithm is written to require objects of particular 
types to make sure certain methods are available.  This can tie 
certain programs to particular object frameworks, which might not 
always be the best way to write a program.  This module tries to 
correct this by allowing interfaces to be defined without creating a 
class.  These interface definitions are called `interfaces' after the 
Java concept (also known as `protocols' in Objective-C).

Interfaces not only allow more flexible tracking of implemented APIs, 
but can also aid in the debugging process during module development.
Any subroutines that are prototyped in an interface are prototyped in 
the using package.  For example, if package A uses interface B, and 
interface B defines subroutine C, then A::C will be prototyped.  Perl 
will then issue warnings if the subsequent subroutine definition 
doesn't match the prototype given in the interface definition.

=head2 DEFINING AN INTERFACE

A interface is defined in the same way a package is defined, except 
using the C<interface> keyword instead of the C<package> keyword:

 use interface;
 interface My::SimpleIO::Interface;

 sub read($);
 sub write($;@);

(N.B.: The following paragraph is subject to change.)
The default file name extension for interface files is C<.pi> instead 
of C<.pm>.  If a C<.pi> file can't be found, then Perl will look for a 
C<.pm> file.  Use C<.pi> when you want the interface to be importable 
without requiring the loading of any code.  Use C<.pm> if code is 
loaded with the interface.  Note that C<perldoc> will not find pod 
that is in a C<.pi> file.  Place the interface documentation in a 
C<.pod> file instead.

You can also sub-class interfaces by using them:

 interface My::MoreAdvanced::IO::Interface;

 use interface My::SimpleIO::Interface;

 sub open($;$);
 sub close($);


If you want to make sure a method is available but don't care about 
the prototype, you can simply declare it without a prototype:

 interface My::Sans::Prototype;

 sub foo;
 sub bar;

Subroutines without prototypes in an interface won't have any effect 
except when you have an explicit check for the interface.

=head2 USING AN INTERFACE

Using an interface is simple:

 use interface qw( interface list );

This will push the interface list onto the package global C<@INTERFACES> 
and prototype any subroutines that have prototypes in the interfaces.
If you want people to think you implement a particular interface without 
getting the benefit of the prototypes, then push the prototype name 
onto the C<@INTERFACES> global without the C<use> statement.  Interfaces 
are not expected to load any code.

Note that a class is considered to implement the interface if any 
super-class implements the interface.  The class does not gain the 
benefit of the prototypes unless it explicitely C<use>s the interface.

=head2 TRACKING INTERFACE SUBSCRIPTIONS

Instead of requiring objects derived from a particular class, you now 
can check that the object implements a particular interface:

  die "Need to be able to read and write"
       unless $object -> implements("My::IO::Interface");

This even works if C<$object>'s class doesn't know anything about 
interfaces.  The C<implements> method will look for the actual methods 
in that case and check their signature against the expected signature 
defined in C<My::IO::Interface>.  If no signature is expected, it 
checks for the method's existance using C<UNIVERSAL::can>.

Interfaces can co-exist with packages.  The package global C<@INTERFACES> 
is used to track interface subscriptions similar to the way C<@ISA> 
tracks class inheritance.  A class has an interface if it is listed in 
the C<@INTERFACES> array, is implemented in a super-class, or is 
implemented implicitely in the class.

=head1 BUGS

There are sure to be some.  The filter is not the most robust and may 
be easily confused.  This is a source filter.
Some areas that need improvement:

=over 4

=item *

Better error reporting (almost non-existent when defining interfaces)

=item *

Anything `out of the ordinary' can lead to undefined results (this 
includes code other than simple prototypes in the interface definition).

=item *

Any code mixed in to the interface definition is ignored.  The interface 
definition is replaced by `1;' in the source that Perl sees after the 
filter.  This also means that line numbers will be off.

=item *

Documentation.

=back


=head1 AUTHOR

James Smith, <jsmith@cpan.org>

=head1 COPYRIGHT

Copyright (C) 2003  Texas A&M University.  All Rights Reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.
