#!/usr/bin/perl -w
package MyPlace::Message::Tee;
our $VERSION = v1.0;
use strict;
use warnings;
sub new {
	my $class = shift;
	my $output = shift;
	my $self = bless {output=>$output,@_},$class;
	return $self;
}

sub put {
	my $self = shift;
	return $self if(!@_);
	if(!$self->{output}) {
		return pmsg(@_);
	}
	if($self->{error}) {
		return pmsg(@_);
	}
	if(!$self->{output_fh}) {
		if(!open $self->{output_fh},($self->{filemode} ? ">>" : ">"),$self->{output}) {
			$self->{error} = 1;
		}
	}
	if($self->{error}) {
		return pmsg(@_);
	}
	print {$self->{output_fh}} @_;
	$self->std_put(@_);
	return $self;
}

sub std_put {
	my $self = shift;
	if($self->{stderr}) {
		print STDERR @_;
	}
	else {
		print STDOUT @_;
	}
	return $self;
}

sub open {
	my $self = shift;
	my $output = shift;
	my $filemode = shift;
	$self->close();
	if(!$output) {
		$self->{error} = 1;
		return $self;
	}
	if($self->{output_fh}) {
		close $self->{output_fh};
	}
	$self->{output} = $output;
	if(defined $filemode) {
		$self->{filemode} = $filemode;
	}
	if(!open $self->{output_fh},($self->{filemode} ? ">>" : ">"),$self->{output}) {
		$self->{error} = 1;
	}
	return $self;
}

sub close {
	my $self = shift;
	close $self->{output_fh} if($self->{output_fh});
	delete $self->{error};
	delete $self->{filemode};
	delete $self->{output_fh};
	delete $self->{output};
	delete $self->{stderr};
}

sub DESTORY {
	my $self = shift;
	$self->close() if($self && ref $self);
	return 1;
}


1;

