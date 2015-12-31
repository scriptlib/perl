#!/usr/bin/perl -w
package MyPlace::Tasks::Tasks;
use strict;
use warnings;
use MyPlace::Tasks::Task;

sub new {
	my $class = CORE::shift;
	my $namespace = @_ ? [@_] : [];
	my $self = bless {namespace=>$namespace},$class;
	$self->{tasks} = [];
	return $self;
}
sub to_string {
	my $self = CORE::shift;
	my @text;
	push @text, "namespace:" . join("::",@{$self->{namespace}});
	foreach(@{$self->{tasks}}) {
		push @text, $_->to_string(" > ");
	}
	return @text;
}

sub load {
	my $self = CORE::shift;
	foreach(@_) {
		chomp;
		next unless($_);
		if(m/^\s*namespace\s*:\s*(.+?)\s*$/) {
			$self->{namespace} = [split(/::/,$1)];
		}
		else {
			my $task = MyPlace::Tasks::Task->new(split(/\s*\t\s*/,$_));
			CORE::push @{$self->{tasks}},$task;
		}
	}
	return $self;
}

sub save {
	my $self = shift;
	my @text;
	push @text, "namespace:" . join("\t",@{$self->{namespace}});
	foreach(@{$self->{tasks}}) {
		push @text, $_->to_string("\t");
	}
	return join("\n",@text),"\n";
}


sub new_from_text {
	my $class = CORE::shift;
	my $self = $class->new();
	$self->load(@_);
	return $self;
}

sub push {
	my $self = CORE::shift;
	push @{$self->{tasks}},@_;
	return $self;
}

sub pop {
	my $self = CORE::shift;
	my $task = pop @{$self->{tasks}};
	return $task;
}

sub unshift {
	my $self = CORE::shift;
	unshift @{$self->{tasks}},@_;
	return $self;
}


sub shift {
	my $self = CORE::shift;
	my $task = shift @{$self->{tasks}};
	return $task;
}

1;
