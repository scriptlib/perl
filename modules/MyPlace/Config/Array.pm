#!/usr/bin/perl -w
package MyPlace::Config::Array;
our $VERSION = "1.0";
use strict;
use warnings;

sub new {
	my $class = shift;
	my $self = bless {
		data=>[],
		keys=>[],
		index=>{},
	},$class;
	if(@_) {
		$self->readfile(@_);
	}
	return $self;
}

sub readtext {
	my $self = shift;
	$self->{data} = [];
	$self->{keys} = [];
	$self->{index} = {};
	my @current;
	foreach(@_) {
		s/[\r\n\s]+$//;
		my $is_empty = undef;
		my $is_content = undef;
		my $is_newitem = undef;
		if(!$_) {
			$is_empty = 1;
		}
		elsif(m/^\s*$/) {
			$is_empty = 1;
		}
		elsif(m/^\s+/) {
			$is_content = 1;
		}
		else {
			$is_newitem = 1;
		}

		if($is_empty and @current) {
			$self->add(@current);
			@current = ();
		}
		elsif($is_content) {
			s/^\s+//;
			push @current,$_;
		}
		elsif($is_newitem) {
			$self->add(@current) if(@current);
			@current = ($_);
		}
	}
	if(@current) {
		$self->add(@current);
	}
	$self->{_DIRTY} = 0;
	return $self->{keys};
}

sub readfile {
	my $self = shift;
	my $filename = shift;
	$self->{lastfile} = $filename;
	return unless(-f $filename);
	if(open FI,'<',$filename) {
		$self->readtext(<FI>);
		close FI;
	}
	else {
		print STDERR  "Error open $filename: $!\n";
	}
	return;
}

sub get_text {
	my $self = shift;
	my @data = @_ ? @_ : @{$self->{data}};
	my @text;
	foreach(@data) {
		if(ref $_) {
			push @text,"\n",join("\n\t",@$_),"\n";
		}
		else {
			push @text,"\n$_\n";
		}
	}
	return @text;
}

sub get_data {
	my $self = shift;
	return @{$self->{data}};
}

sub writefile {
	my $self = shift;
	my $filename = shift(@_) || $self->{lastfile};
	if(! -w $filename) {
		print STDERR "File not writable: $filename\n";
		return undef;
	}
	if(open FO,'>',$filename) {
		print STDERR "Writting $filename ...";
		print FO $self->get_text(@_);
		close FO;
		print STDERR "\t[OK]\n";
		$self->{_DIRTY} = 0;
	}
	else {
		print STDERR "Error writting $filename: $!\n";
		return undef;
	}
}

sub add {
	my $self = shift;
	my @current = @_;
	return unless(@current);
	push @{$self->{data}},[@current];
	push @{$self->{keys}},$current[0];
	$self->{index}->{$current[0]}=$#{$self->{data}};
	$self->{_DIRTY} = 1;
	return $self;
}

sub index {
	my $self = shift;
	my $key = shift;
	return $self->{index}{$key};
}

sub get {
	my $self = shift;
	my $key = shift;
	my $idx = $self->{index}{$key};
	if(defined $idx) {
		return $self->{data}[$idx] ? @${$self->{data}[$idx]} : ();
	}
}

sub set {
	my $self = shift;
	my $key = shift;
	my $idx = $self->{index}{$key};
	if(defined $idx) {
		$self->{data}[$idx] = [$key,@_];
	}
	else {
		$self->add($key,@_);
	}
	$self->{_DIRTY} = 1;
	return $self;
}

sub delete {
	my $self = shift;
	my @keys = @_;
	return unless(@keys);
	my $count=0;
	foreach my $key(@keys) {
		my $idx = $self->{index}->{$key};
		if(defined $idx) {
			$count++;
			delete $self->{data}->[$idx];
			print STDERR "Data with key [$key] deleted\n";
		}
		else {
			print STDERR "Data with key [$key] not found\n";
		}
	}
	if($count) {
		$self->reset(@{$self->{data}});
		return 1;
	}
	else {
		return undef;
	}
}

sub dump {
	my $self = shift;
	require Data::Dumper;
	return Data::Dumper::Dumper($self->{data});
}

sub reset {
	my $self = shift;
	my @data = @_;
	$self->{data} = [];
	$self->{keys} = [];
	$self->{index} = {};
	if(@data) {
		$self->add(@$_) foreach(@data);
	}
	$self->{_DIRTY} = 1;
	return $self;
}

sub sort {
	my $self = shift;
	my @data = @{$self->{data}};
	$self->reset(sort {$a->[0] cmp $b->[0]} @data);
	return $self->{data};
}

sub isdirty {
	my $self = shift;
	return $self->{_DIRTY};
}


1;

__END__

=pod

=head1  NAME

MyPlace::Config::Array - A simple configuration file format

=head1  SYNOPSIS

	use MyPlace::Config::Array;
	omy $A = MyPlace::Config::Array->new();
	$A->add('key1','v1','v2','v3');
	$A->delete('key1','key2');
	$A->get('key2');
	$A->set('key2','what ever','is good');
	my @data = $A->get_data();
	print $A->get_text();
	print $A->get_dump();

=head1  DESCRIPTION

A simple configuration file format.
As simple as a blank line seperated text file.
But works good enough.

=head1  CHANGELOG

    2014-11-23 01:26  xiaoranzzz  <xiaoranzzz@MyPlace>
        
        * file created.

=head1  AUTHOR

xiaoranzzz <xiaoranzzz@MyPlace>

=cut

#       vim:filetype=perl
