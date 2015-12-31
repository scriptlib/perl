#!/usr/bin/perl -w
package MyPlace::Google;

use MyPlace::Google::Search::HTML;

sub new {
    my $class = shift;
    return bless {@_},$class;
}

sub search {
	my $self = shift;
	if($self and ref $self) {
	}
	else {
		unshift @_,$self;
	}
	return MyPlace::Google::Search::HTML::search(@_);
}

sub search_web {
	my $self = shift;
	if($self and ref $self) {
		return $self->search('web',@_);
	}
	else {
		unshift @_,$self;
		return &search('web',@_);
	}
}

sub search_images {
	my $self = shift;
	if($self and ref $self) {
		return $self->search('images',@_);
	}
	else {
		unshift @_,$self;
		return &search('images',@_);
	}
}

1;
