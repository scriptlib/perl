#!/usr/bin/perl -w
package DayShooter::Server;
use strict;

sub new {
    my $class = shift;
    return bless {@_},$class;
}

sub run {
    my $self = shift;
    $self->{is_running}=1;
}

sub callback {
    my($self,$caller,$name,@args) = @_;
    if($name eq 'open_uri') {
        if($self->{worker}) {
            my($ok,$type,$data) = $self->{worker}->handle($name,@args);
            if($ok) {
                if($type = "uri") {
                    return $caller->open_uri($data);
                }
                else {
                    return $caller->set_data($data);
                }
            }
            else {
                return undef;
            }
        }
        else {
            return undef;
        }
    }
    else {
        return;
    }
}

sub is_running {
    my $self = shift;
    return $self->{is_running};
}
1;
