#!/usr/bin/perl -w
use strict;
use warnings;
package MyPlace::History;

sub new {
	my $class = shift;
	my $self =  bless {},$class;
	$self->{storage} = $_[0] || '.myplace.history.db';
	$self->{database} = {};
	return $self;
}
sub add {
	my $self = shift;
	my $url = shift;
	return undef if($self->{database}->{$url});
	$self->{database}->{$url} = 1;
	print {$self->{storage_handler}} "$url\n";
	return 1;
}

sub close {
	my $self = shift;
	close $self->{storage_handler} if($self->{storage_handler});
}
sub save {
	my $self = shift;
	return $self->close(@_);
}
sub load{
	my $self = shift;
	my $storage = $_[0] || $self->{storage} || '.myplace.history.db';
	$self->{storage} = $storage;
	if(open FI,'<',$storage) {
		foreach(<FI>) {
			chomp;
			$self->{database}->{$_}=1;
		}
		CORE::close FI;
	}
	open my $FO, ">>",$storage;
	$self->{storage_handler}= $FO;
	return $FO;
}
sub check {
	my $self = shift;
	foreach(@_) {
		return 1 if($self->{database}->{$_});
	}
	return undef;
}

sub notify_next {
	my $self = shift;
	my $next = shift;
	my $addlast = shift;
	$self->add_last() if($addlast);
	$self->{lasttask}=$next;
	return $next;
}
sub add_last {
	my $self = shift;
	$self->add($self->{lasttask}) if($self->{lasttask});
}

sub DESTORY {
	my $self = shift;
	$self->save() if(ref $self);
}

1;
__END__

