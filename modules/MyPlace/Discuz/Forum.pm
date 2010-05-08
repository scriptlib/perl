package MyPlace::Discuz::Forum;

use HTML::TreeBuilder;
use MyPlace::HTML::Convertor;

sub new() {
    my $class=shift;
    my $self = bless{} ,$class;
    my @data;
    return unless($_[0]);
    if( $_[0] eq '-') {
        @data=<STDIN>;
    }
    elsif($_[0] =~ /\n/) {
        @data=@_;
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
    $title = $title->as_text;
    $self->{title}=$title ? $title : "";
    my @forums = $tree->look_down("class",qr/^mainbox forumlist$/i);
    foreach(@forums) {
        my @links = $_->look_down("_tag","a","href",qr/forum/);
        foreach(@links) {
            push @{$self->{forums}},[$_->attr("href"),$_->as_text];
        }
    }
    my @threads = $tree->look_down("id",qr/^thread/i);
    foreach my $thread (@threads) {
        my @links = $thread->look_down("_tag","a","href",qr/thread/);
        push @{$self->{threads}},[$_->attr("href"),$_->as_text] foreach(@links);
    }
    my ($pages) = $tree->look_down("class","pages_btns");
    if($pages) {
        my $min=10000;
        my $max=1;
        my $pre="";
        my $suf="";
        my @pages =  $pages->look_down("_tag","a","href",qr/forum/);
        foreach (@pages) {
            if($_->attr("href") =~ m/(forum-\d+-)(\d+)(.+)$/) {
               $pre=$1 unless($pre);
               $suf=$3 unless($suf);
               $min = $2 if($2 < $min);
               $max = $2 if($2 > $max);
            }
        }
        $self->{pages} = [map {$pre . $_ . $suf} ($min .. $max)] if($min<=$max);
    }
    my @postcontent = $tree->look_down("class","postmessage defaultpost");#postcontent");
    #$self->{post_content} = $postcontent[0] if(@postcontent);
    foreach(@postcontent) {
        my @imgs = $_->look_down("_tag","img","src",qr/.+/);
        my $text = text_from_node($_);
        push @{$self->{posts}},[$text,[map $_->attr("src"),@imgs]];
    }
    $self->{post}=$self->{posts}->[0] if($self->{posts});
    if($self->{post}) {
        $self->{post_text}=$self->{post}->[0];
        $self->{post_images}=$self->{post}->[1];
    }

    $tree->delete();
    return $self;
}

sub free {
}

1;
