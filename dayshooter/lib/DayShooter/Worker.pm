#!/usr/bin/perl -w
package DayShooter::Worker;

sub new {
    my $class = shift;
    return bless {@_},$class;
}

sub handler {
    my $self = shift;
    return undef,undef,undef;
}
1;
