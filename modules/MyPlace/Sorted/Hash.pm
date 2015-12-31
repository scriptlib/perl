#!/usr/bin/perl -w
use strict;
use warnings;
our $version = 'v1.0';
my $PKP = '_MYPLACE_SORTED_HASH_PRIVATE';

sub new {
	my $class = shift;
	my $self = bless {},$class;
	$self->init(@_);
	$self->set(@_) if(@_);
	return $self;
}

sub reset {
	my $self = shift;
	$self->{$PKP . "_KEYS"} = [];
	$self->{$PKP . "_DATA"} = {};
	return $self;
}

sub init {
	my $self = shift;
	$self->reset();
	$self->set(@_) if(@_);
	return $self;
}

sub keys {
	my $self = shift;
	if($self->{$PKP . '_KEYS'}) {
		return @{$self->{$PKP . "_KEYS"}};
	}
	else {
		return ();
	}
}

sub set {
	my $self = shift;
	my %DATA = @_;
	my $HD = $self->{$PKP . "_DATA"};
	if(!$HD) {
		$self->{$PKP . "_DATA"} = {};
		$HD = $self->{$PKP . "_DATA"};
	}
	foreach (CORE::keys(%DATA)) {
		if($HD->{$_}) {
			push @{$self->{$PKP . "_KEYS"}},$_;
			$HD->{$_} = $DATA{$_};
		}
		else {
			$HD->{$_} = $DATA{$_};
		}
	}
}

sub get {
	my $self = shift;
	my $HD = $self->{$PKP . "_DATA"};
	if(!$HD) {
		$self->{$PKP . "_DATA"} = {};
		$HD = $self->{$PKP . "_DATA"};
	}
	my @r;
	foreach(@_) {
		push @r,$HD->{$_};
	}
	return @r;
}

sub delete {
	my $self = shift;
	my $HD = $self->{$PKP . "_DATA"};
	if(!$HD) {
		$self->{$PKP . "_DATA"} = {};
		$HD = $self->{$PKP . "_DATA"};
	}
	my @r;
	foreach(@_) {
		if(defined $HD->{$_}) {
			push @r,$_;
			delete $HD->{$_};
		}
	}
	my @newkeys;
	foreach my $pre (@{$self->{$PKP . "_KEYS"}}) {
		my $match = 0;
		foreach(@r) {
			if($pre eq $_) {
				$match = 1;
				last;
			}
		}
		push @newkeys,$pre unless($match);
	}
	$self->{$PKP . "_KEYS"} = [@newkeys];
}

1;

