#!/usr/bin/perl -w
package MyPlace::FileTasks;
use strict;
use warnings;
use parent 'MyPlace::Tasks';
use MyPlace::Tasks::Task;

sub new {
	my $class = shift;
	my $file = shift;
	my $path = shift;
	my ($namespace,@prefix) = parse_path($path);
	my $self = $class->SUPER::new($namespace,@_);
	$self->{_file} = $file;
	$self->{_prefix} = [@prefix];
	$self->load_file();
	return $self;
}

sub parse_path {
	my $dirname = shift;
	$dirname =~ s/\.(?:txt|md)$//;
	return split(/[\\\/]/,$dirname);
}

sub save_file {
	my $self = shift;
	my $file = shift(@_) || $self->{_file};
	if(!$file) {
		print STDERR "[FileTasks} Error, can't write anything to nothing\n";
		return;
	}
	if(!open FO,'>',$file) {
		print STDERR "[FileTasks] Error writting file $file\n";
		return;
	}
	foreach(@{$self->{_text}}) {
		print FO $_,"\n";
	}
	close FO;
}

sub dirty {
	my $self = shift;
	return $self->{_modified};
}

sub load_file {
	my $self = shift;
	my $file = shift(@_) || $self->{_file};
	$self->reset();
	$self->{_modified} = 0;
	if(!$file) {
		print STDERR "[FileTasks} Error, load nothing from nothing\n";
		return;
	}
	if(! -f $file) {
		print STDERR "[FileTasks] Error, file not exist: $file\n";
		return;
	}
	if(!open FI,'<',$file) {
		print STDERR "[FileTasks] Error opening file $file\n";
		return;
	}
	my @text;
	foreach(<FI>) {
		chomp;
		if(!$_) {
			push @text,$_;
			next;
		}
		elsif(m/^\s*>/) {
			push @text,$_;
			next;
		}
		else {
			$self->{_modified} = 1;
			push @text,">$_";
		}	
		$self->push(@{$self->{_prefix}},split(/\s*(?:[\>\?\t]+|\\t)\s*/,$_));
	}
	close FI;
	$self->{_text} = [@text];
	if(!@text) {
		$self->push(@{$self->{_prefix}});
	}
	return $self;
}


1;

