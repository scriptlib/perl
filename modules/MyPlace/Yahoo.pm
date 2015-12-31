#!/usr/bin/perl -w
package MyPlace::Yahoo;
use MyPlace::Yahoo::BOSS;

sub new {
    my $class = shift;
    return bless {},$class;
}

sub BOSS {
    my $self=shift;
    my $func=shift;
    my @args=@_;
    return eval "MyPlace::Yahoo::BOSS::$func(@args);"
}

1;
