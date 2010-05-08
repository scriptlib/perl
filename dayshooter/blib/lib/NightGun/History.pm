#!/usr/bin/perl -w
package NightGun::History;
use NightGun;
use strict;
no warnings;

sub new {
    my ($class,$config)=@_;
    my $self = bless {
        },$class;
    $config->{History}={} unless($config->{History});
    $self->{data}=$config->{History};
    #use Data::Dumper;print Dumper($self->{data}),"\n";
    return $self;
}

sub add {
    my ($self,$file,@info)=@_;
	if($file) {
	    $self->{data}->{$file}=\@info;
		NightGun::message("History","add ",$file,":",join(" ",@info));
	}
}

sub get {
    my ($self,$file)=@_;
    return undef unless($self->{data}->{$file});
	NightGun::message("History","get ",$file,":",join(" ",@{$self->{data}{$file}}));
    return @{$self->{data}->{$file}};
}
sub save {
    return;
}
1;
