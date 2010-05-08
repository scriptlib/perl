#!/usr/bin/perl -w
package DayShooter;
use strict;

use DayShooter::Server;
use DayShooter::Client;
use DayShooter::Worker;

my %clients;

sub new {
    my $class = shift;
    return bless {@_},$class;
}

sub start {
    my $self = shift;
    my %config = (appdir=>$self->{appdir},libdir=>$self->{libdir});
    $self->{worker} = new DayShooter::Worker(%config) unless($self->{worker});
    $self->{server} = new DayShooter::Server(worker=>$self->{worker},%config) unless($self->{server});
    my $client = new DayShooter::Client(server=>$self->{server},%config);
    $clients{$client}=1;
    $self->{server}->run(@_) unless($self->{server}->is_running);
    return $client->run(@_);
}

sub end {
    return 1;
}

sub active {
    foreach(keys %clients) {
        if($clients{$_}) {
            $_->active();
        }
    }
}
1;
