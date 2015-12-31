#!/usr/bin/perl -w
use strict;
use warnings;
package MyPlace::ProgramCenter;

sub new {
	my $class = shift;
	return bless {},$class;
}

sub notify {
	my $self = shift;
	if($self->{main}) {
		return $self->{prog}->(@_);
	}
}

sub prog {
	my $self = shift;
	$self->{prog} = $_[0];
	return $self;
}

1;
__END__
