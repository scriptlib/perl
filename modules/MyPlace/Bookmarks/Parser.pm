#!/usr/bin/perl -w
package MyPlace::Bookmarks::Parser;
use strict;
use warnings;
BEGIN {
    require Exporter;
    our ($VERSION,@ISA,@EXPORT,@EXPORT_OK,%EXPORT_TAGS);
    $VERSION        = 1.00;
    @ISA            = qw(Exporter);
    @EXPORT         = qw();
    @EXPORT_OK      = qw();
}
use HTML::TreeBuilder;
use HTML::Element;
use Encode;

sub new {my $class = shift;return bless {@_},$class;}

sub parse_file {
	my $self = shift;
	my $file = shift || $self->{file};
	my $charset = shift || $self->{charset} || 'utf8';
	my @text;
	if($charset eq 'utf8') {
		open FI,'<:' . $charset,$file or return undef,$!;
	@text = <FI>;
		close FI;
	}
	else {
		open FI,'<',$file or return undef,$!;
		my $dec = find_encoding($charset);
		@text = <FI>;
		if(ref $dec) {
			map {$dec->decode($_);} @text;
		}
		close FI;
	}
	return $self->parse_content(\@text);
}

sub find_bookmarks {
	my $self = shift;
	my $top = shift;
	my $bookmarks = shift;
	my $name = "";
	if(ref $top and $top->tag eq 'dl') {
		my @list = $top->content_list;
		my $dl = {name=>'',nodes=>[]};
		my @dts;
		while(@list) {
			$_ = shift @list;
			next unless($_);
			if(!ref $_) {
				$name .= $_;
				next;
			}
			my $tag = $_->tag;
#			print STDERR $tag;
			if($tag eq 'dt') {
				my %current = ();
				foreach my $a ($_->content_list) {
					if(ref $a and $a->tag eq 'a') {
						$current{href} = $a->attr('href');
						$current{tags} = $a->attr('tags');
						$current{text} = $a->as_text;
						last;
					}
				}
				if($current{href}) {
					my $dd = shift @list;
					if(ref $dd and $dd->tag eq 'dd') {
						$current{desc} = $dd->as_text;
						$current{desc} =~ s/\s+$//;
					}
					else {
						unshift @list,$dd;
					}
					push @{$dl->{nodes}},\%current;
				}
			}
			elsif($tag eq 'dl') {
				$self->find_bookmarks($_,$dl->{nodes});
			}
		}
		$dl->{name} = $name;
		push @{$bookmarks},$dl;
	}
}

sub parse_content {
	my $self = shift;
	my $text = shift;
	my $tree = HTML::TreeBuilder->new_from_content(@{$text});
	$self->{tree} = $tree;
	my @bookmarks = ();
	my ($body) = $tree->find('body');
	foreach($body->content_list) {
		$self->find_bookmarks($_,\@bookmarks);
	}
	#use Data::Dumper;print Data::Dumper->Dump([\@bookmarks],['*bookmarks']);
	return \@bookmarks;
}

sub DESTROY {
	my $self = shift;
	if($self->{tree} and ref $self->{tree}) {
		$self->{tree}->delete();
	}
}

1;

__END__
=pod

=head1  NAME

MyPlace::Bookmarks::Parser - PERL Module

=head1  SYNOPSIS

use MyPlace::Bookmarks::Parser;

=head1  DESCRIPTION

___DESC___

=head1  CHANGELOG

    2011-12-30 16:32  xiaoranzzz  <xiaoranzzz@myplace.hell>
        
        * file created.

=head1  AUTHOR

xiaoranzzz <xiaoranzzz@myplace.hell>


# vim:filetype=perl
