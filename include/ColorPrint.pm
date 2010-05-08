#!/usr/bin/perl
package AppMessage;
use Term::ANSIColor;


my $id = $0;
$id =~ s/^.*\///g;

sub printId{
    print STDERR color('white'),"$id> ",color('reset');
}
sub error {
    printId();
    print STDERR color('red'),@_,color('reset');
}

sub message {
    printId();
    print STDERR color('green'),@_,color('reset');
}

sub warning {
    printId();
    print STDERR color('yellow'),@_,color('reset');
}

sub abort {
    &error(@_);
    exit $?;
}
