#!/usr/bin/perl -w
package MyPlace::Discuz::Index;
use strict;
use warnings;
use HTML::TreeBuilder;
sub new {
    my $class=shift;
    my $self = bless{} ,$class;
    my @data;
    return unless($_[0]);
    if($_[0] eq '-') {
        @data=<STDIN>;
    }
    elsif (-f $_[0]) {
        open FI,"<",$_[0];
        @data=<FI>;
        close FI;
    }
    else {
        @data=@_;
    }
    my $tree = HTML::TreeBuilder->new_from_content(@data);
    my ($title) = $tree->look_down("_tag",qr/title/i);
    $title = $title->content;
    $self->{title}=$title ? $title : "";
    my @forums = $tree->look_down("id",qr/^forum\d+$/i);
    $self->{forums}=[];
    foreach(@forums) {
        my @links = $_->look_down("_tag","a","href",qr/forum/);
        foreach(@links) {
            push @{$self->{forums}},{href=>$_->attr("href"),text=>$_->as_text};
        }
    }
    return $self;
}
return 1;

