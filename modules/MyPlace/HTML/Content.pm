#!/usr/bin/perl -w
package MyPlace::HTML::Content;
use utf8;
use HTML::TreeBuilder;
use MyPlace::HTML::Convertor;
use Encode qw/decode/;

sub new {
    my $class = shift;
    my $self = bless {_bodyid=>[@_]},$class;
    $self->{_tree} = HTML::TreeBuilder->new(); 
    return $self;
}

sub parse {
    my $self = shift;
    $self->{_tree}->parse($_) foreach(@_);
}

sub eof {
    my $self = shift;
    $self->{_tree}->eof();
    _build_content($self);
    return $self;
}

sub new_from_file {
   my ($class,$file,@bodyid) = @_;
   my $self = bless {filename=>$file,_bodyid=>[@bodyid]},$class;
   open my $fh,"<",$file or return $self;
   my @data = _read_html($fh);
   close $fh;
   $self->{_tree} = HTML::TreeBuilder->new_from_content(@data);
   _build_content($self);
   return $self;
}

sub _build_content {
    my $self = shift;
    $self->{title} = _get_title($self->{_tree},$self->{filename});
    my $body = _get_body($self->{_tree},$self->{_bodyid});
    my @images = $body->look_down(_tag=>"img",src=>qr/\.(:?png|jpeg|jpg)/i);
    push @{$self->{images}},$_->attr("src") foreach(@images) ;
    $self->{text} = text_from_node($body);
    $body = undef;
    $self->{_tree}->delete();
#    $self->{_tree}=undef;
    #use Data::Dumper;print STDERR Dumper($self),"\n";
}

sub _get_body {
    my $tree = shift;
    my $body_id = shift;
    return $tree unless($body_id);
    foreach(@{$body_id}) {
        my ($body) = $tree->look_down(%{$_});
        return $body if($body);
    }
    return $tree;
}
use constant {
    PAIRS=>[
        [qw/【 】/],
#        [qw/\( \)/],
        [qw/\[ \]/],
#        [qw/（ ）/],
    ],
    PAIR_LIST=>'【】\(\)\[\]（）',
};
sub _get_title {
    my $tree = shift;
    my $file = shift;
    my ($title) = $tree->look_down("_tag","title");
    $title =  $title->as_text() if($title);
    unless($title) {
        $title = $file;
        return "no_title" unless($title);
        $title =~ s/.*\///;
        $title =~ s/\..*$//g;
    }
#    print STDERR "From \"$title\" to ";
    $title =~ s/[\[【\s]*\d+-\d+-\d+[\]】\s]*//g;
    $title =~ s/5u.*//g;
    $title =~ s/[\/\\\!\*\+]//g;
    my $pair_exp = '\s*-[^' . PAIR_LIST . ']*';
    $title =~ s/$pair_exp$//g;
#    die($pair_exp,"\n");
    foreach(@{&PAIRS}) {
        my ($s,$e) = @{$_};
        $title =~ s/\s*$s([^$s$e]*)$e\s*/$1/g;
    }
    $title =~ s/^\s+//;
    $title =~ s/\s+$//;
    $title = "no_title" unless($title);
#    print STDERR "\"$title\"\n";
    return $title;
}

sub _read_html {
    my $fh = shift;
    my @data;my $charset;
    while(<$fh>) {
        chomp;
        next if(/^\s*$/);
        push @data,$_;
        if(!$charset && /charset\s*=[\s'"]*([^\/\\\s<>"']+)/) {
            $charset=$1;
            $charset="utf8" if($charset =~ /utf/);
            $charset="gbk" if($charset =~ /gb2312/);
        }
    }
    @data = map {$_=decode($charset,$_);} @data if($charset);
    #print STDERR Dumper(\@data),"\n";
    return @data;
}
return 1;
