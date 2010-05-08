#!/usr/bin/perl -w
package NightGun::Store::WebSaver;
use warnings;
use base qw/NightGun::Store/;
use strict;
my $path_sep = "::WebSaver::";
my $location_exp = qr/^(.*)$path_sep(.*)$/;

sub new {
	return NightGun::Store::new(@_);
}

sub load {
	my($self,$path,$data)=@_;
	my ($source,$entry,@data);
	if($path =~ $location_exp) {
		$source = $1;
		$entry = $2;
	}
	else {
		$source = $path;
	}

	if($data) {
		@data = ($data);
	}
	elsif(-f $source) {
		open FI,"<",$source or return undef;
		@data=<FI>;
		close FI;
	}
	else {
		return undef;
	}
	foreach(@data) {
		next unless($_);
		return undef unless($_ =~ /^\s*\<\s*topic/i);
		last;
	}
		$self->{files}=undef;
		$self->{dirs}=undef;
		$self->{root}=$source;
		$self->{id}=$path;
		$self->{data}=undef;
		$self->{type}=NightGun::Store->TYPE_STREAM;
		$self->{parent}=$source;
		$self->{parent} =~ s/\/[^\/]+$//;
	if($entry) {
		my $text = join("",@data);
		$text =~ s/^.*\<\s*Item\s+[^<>]*label="$entry"\s*[^\<\>]*\>[^\<\>]*\<!\[CDATA\[//i;
		$text =~ s/\]\].*$//;
		$self->{leaf}=$source . $path_sep . $entry;
		$self->{title}=$entry;
		print $text;
		$self->{data}=$text;
	}
	else {
		foreach(@data) {
			my @match = $_ =~ /\<\s*Item\s+[^<>]*label="([^"]+)"\s+/ig;
			next unless(@match);
			push @{$self->{files}},map $source . $path_sep . $_,@match;
		}
		$self->{leaf}="";
		$self->{title}=$source;
		$self->{title} =~ s/^.*\///;
	}
	return $self;
}

sub parse_location {
	my($self,$path)=@_;
	return undef unless($path =~ $location_exp);
	return ($1,$path);
}
