#!/usr/bin/perl -w
package NightGun::Store::WWW;
use NightGun;
use strict;
use base qw/NightGun::Store/;
my $PACKAGE_NAME="NightGun::Store::WWW";

sub new {
	my $class = shift;
	return NightGun::Store::new($class);
}

sub load {
    my ($self,$path,$data) = @_;
	return undef if($data);
    my $source = _parse_entry($path);
	return undef unless($source);
	$self->{name}=$source;
	$self->{parent}=$source;
	$self->{data}=$source;
	$self->{type}=NightGun::Store::TYPE_URI;
	$self->{files}=undef;
	$self->{dirs}=undef;
    $self->{title}=$source;
    $self->{id}=$self->{name};
	$self->{root}=$source;
	$self->{leaf}="";
    return $self;
}

sub _parse_entry {
    my $path = shift;
	if($path =~ /^\//) {
		return undef;
	}
	return $path;

#	elsif($path =~ /^(:?file|jar|http|ftp):\/\//) {
#		return $path;
#	}
#	elsif($path =~ /
#    $path =~ s/^jar:file://ig;
#    $path =~ s/^\/+/\//;
#    $path =~ s/!\//$PATH_SEP\//;
#    if($path =~ $PATH_EXP) {
#        return $1,$2;
#    }
#    else {
#        return $path,"";
#    }
}
sub parse_location {
    my $self = shift;
    my $path = shift;
	return ($path,"");
}
1;
