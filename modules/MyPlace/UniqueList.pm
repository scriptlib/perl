#!/usr/bin/perl -w
package MyPlace::UniqueList;
use strict;
use warnings;

sub new {
	my $class = shift;
	my $self = bless {@_},$class;
	$self->{itemName} = 'item' unless($self->{itemName});
	$self->{itemsName} = 'items' unless($self->{itemsName});
	if($self->{file}) {
		$self->load();
	}
	else {
		$self->{list} = [];
		$self->{hash} = {};
		$self->{dirty} = 0;
	}
	return $self;
}

sub load {
	my($self,$file) = @_;
	$file = $self->{file} unless($file);
	if(!$file) {
		die("No file specified\n");
	}
	$self->{list} = [];
	$self->{hash} = {};
	$self->{dirty} = 0;
	if(-f $file) {
		open FI,'<',$file or die("reading $file: $!\n");
		foreach(<FI>) {
			chomp;
			$self->{hash}->{$_} = 1;
		}
		close FI;
	};
	$self->{list} = [keys %{$self->{hash}}];
	if($self->{message}) {
		my $count = @{$self->{list}};
		my $name = $count ? $self->{itemsName} : $self->{itemName};
		#app_message(with_color("^(CYAN)Read ^(YELLOW)$count^(CYAN) $name from [$file]\n"));
	}
	return $self;
}

sub save {
	my($self,$file) = @_;
	$file = $self->{file} unless($file);
	if(!$file) {
		die("No file specified\n");
	}
	if(!$self->{dirty}) {
		my $count = @{$self->{list}};
		my $name = $count ? $self->{itemsName} : $self->{itemName};
		#app_message(with_color("^(YELLOW)$count^(CYAN) $name in [$file]\n"));
		return undef;
	}
	open FO,'>',$file or die("writting $file: $!\n");
	if($self->{list}) {
		print FO map "$_\n",@{$self->{list}};
	}
	close FI;
	$self->{dirty} = 0;
	if($self->{message}) {
		my $count = @{$self->{list}};
		my $name = $count ? $self->{itemsName} : $self->{itemName};
		#app_message(with_color("^(CYAN)Write ^(YELLOW)$count^(CYAN) $name to [$file]\n"));
	}
	return $self;
}

sub check {
	my($self,$item) = @_;
	if(defined $self->{hash}->{$item}) {
		return 1;
	}
	elsif($self->{autoAdd}) {
		$self->{hash}->{$item} = 1;
		push @{$self->{list}},$item;
		$self->{dirty} = 1;
	}
	return undef;
}

sub add {
	my($self,$item) = @_;
	if(defined $self->{hash}->{$item}) {
		return undef;
	}
	$self->{hash}->{$item} = 1;
	push @{$self->{list}},$item;
	$self->{dirty} = 1;
	return 1;
}

sub list {
	my $self = shift;
	return (@{$self->{list}});
}

sub DESTORY {
	my $self = shift;
	if($self->{autoSave}) {
		$self->save;
	}
}

1;

__END__
=pod

=head1  NAME

MyPlace::UniqueList - PERL Module

=head1  SYNOPSIS

use MyPlace::UniqueList;

=head1  DESCRIPTION

___DESC___

=head1  CHANGELOG

    2012-01-12 23:44  xiaoranzzz  <xiaoranzzz@myplace.hell>
        
        * file created.

=head1  AUTHOR

xiaoranzzz <xiaoranzzz@myplace.hell>


# vim:filetype=perl

