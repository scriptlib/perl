#!/usr/bin/perl -w
package MyPlace::Google::Search::HTML;
use strict;
use JSON;
use LWP::UserAgent;
use URI::Escape;
use constant {
    APPID=>'BlVF2czV34FVChK2mzsN7SBghcl.NwZ4YayhlbBXiYxPnRScC49U1ja4HnnF',
    IMAGE_SEARCH_REFER=>'http://images.google.com',
    URL_ID=>'url',
    DEFAULT_COUNT=>18,
    MAX_COUNT=>18,
    DATA_ID=>'results',
};
my @GOOGLE_IP = (
#    'www.google.com',
    '72.14.204.95',
    '72.14.204.96',
    '72.14.204.98',
    '72.14.204.99',
    '72.14.204.103',
    '72.14.204.104',
    '72.14.204.147',
    '72.14.204.148',
    '72.14.213.103',
    '74.125.71.106',
    '209.85.229.99',
    '209.85.225.105',
    '209.85.227.147',
    '209.85.227.100',
    '209.85.227.104',
    '209.85.227.103',
    '216.239.59.147',
);
#http://images.google.com/images?hl=en&newwindow=1&safe=off&as_st=y&tbs=isch%3A1%2Cisz%3Alt%2Cislt%3Axga&sa=1&q=%22Michelle+Marsh%22+nude&aq=f&aqi=&aql=&oq=&gs_rfai=
#http://www.google.com/images?q=Jordan+Carver&um=1&hl=en&newwindow=1&safe=off&tbs=isch:1,isz:lt,islt:2mp
my @VALID_PARAMS =(
    'start',
    'safe',
    'hl',
    'um',
    'source',
    'imgsz',
);
        #valid size is
        #icon
        #medium
        #large
        #xlarge
        #xxlarge
        #valid dimensions is
        #qsvga  >400x300
        #vga    >640x480
        #svga   >800x600
        #xga    >1024x768 
        #2mp    >1600x1200
        #4mp    >2272x1704
        #6mp    >2816x2112
        #8mp    >3264x2448
        #10mp   >3648x2736
        #12mp   >4096x3072
        #15mp   >4480x3360
        #20mp   >5120x3840
        #40mp   >7216x5412
        #70mp   >9600x7200

my $HTTP;

sub get_google_ip {
   return $GOOGLE_IP[int(rand(@GOOGLE_IP))]; 
}

sub get_api_url {
    my ($vertical,$query,%params) = @_;
    my %valid_params = (
        safe=>"off",
        hl=>'en',
    );
    foreach(@VALID_PARAMS) {
        $valid_params{$_} = $params{$_} if($params{$_});
    }
#    $valid_params{ndsp}=$params{count} if($params{count});
    $valid_params{safe}=$params{filter} eq 'no' ? 'off' : 'on'  if($params{filter});
    $valid_params{hl}=$params{lang} if($params{lang});
    $valid_params{hl}=$params{region} if($params{region});

    if($params{dimensions}) {
        $valid_params{tbs}='isch:1,isz:lt,islt:' . $params{dimensions};
    }
    elsif($params{size}) {
        $valid_params{imgsz}=$params{size};
    }


    #my $params = join("&",map ("$_=" . uri_escape($valid_params{$_}),keys %valid_params));
    my $params = join("&",map ("$_=" . $valid_params{$_},keys %valid_params));
#    return IMAGE_SEARCH . "?q=$query&$params";
    return 'http://' . &get_google_ip()  . "/images?q=$query&$params";
#    return "http://images.google.com/imghp",('q'=>$query,%valid_params);
}

sub new {
    my $class = shift;
    return bless {@_},$class;
}

sub get_count {
    my %args = @_;
    return DEFAULT_COUNT unless($args{count});
    return $args{count}>MAX_COUNT ? MAX_COUNT : $args{count};
}

sub grep_size {
    my ($pattern,$images)=@_;
    return $images unless($pattern);
    return "No results." unless($images and @{$images});
    my @result;
    if($pattern =~ /^>(\d+)/) {
        @result = grep $_->{size}>$1,@{$images}; 
    }
    elsif($pattern =~ /^<(\d+)/) {
        @result = grep $_->{size}<$1,@{$images}; 
    }
    elsif($pattern =~ /^=?=?(\d+)/) {
        @result = grep $_->{size}==$1,@{$images}; 
    }
    return "Result all filter out." unless(@result);
    return \@result;
}
sub _make_data {
    my $org = shift;
    my $data_id = shift;
    my $result = {$data_id=>[]};
    return $result unless($org and @{$org});
    foreach(@{$org}) {
        my %cur = (
                "clickurl"=>$_->[0],
                "target"=>$_->[1],
                "id"=>$_->[2],
                "url"=>$_->[3],
                "twidth"=>$_->[4],
                "theight"=>$_->[5],
                "title"=>$_->[6],
                "filetype"=>$_->[10],
                "referurl"=>$_->[11],
                "thumburl"=>$_->[14],
        );
        if($_->[9] =~ /(\d+)\s*\&times;\s*(\d+)\s*-\s*(\d+)([kKmM]?)/) {
            $cur{width}=$1;
            $cur{height}=$2;
            $cur{size}=$3;
            my $size_k=$4;
            if($size_k eq 'k' or $size_k eq 'K') {
                $cur{size} *= 1000;
            }
            elsif($size_k eq 'm' or $size_k eq 'M') {
                $cur{size} *= 1000*1000;
            }
        }
        push @{$result->{$data_id}},\%cur;
    }
    return $result;
}
sub search {
    my $self = shift;
    unshift @_,$self unless($self and ref $self);
    my($ajax,$data_id,$refer,$keyword,%args)=@_;
    if($args{count}) {
        $args{count}=MAX_COUNT if($args{count}>MAX_COUNT);
    }
    else {
        $args{count}=DEFAULT_COUNT;
    }
    my ($URL,%params) = &get_api_url($ajax,$keyword,%args);
#    print STDERR "Retriving $URL...\n";
    if(!$HTTP) {
        $HTTP = LWP::UserAgent->new();
        $HTTP->agent("Mozilla/5.0 (X11; U; Linux i686; en-US; rv:1.9.0.3) Gecko/2008092416 Firefox/3.0.3 Firefox/3.0.1");
    }
   # my $res = $HTTP->post($URL,[%params]);#get($URL,"referer"=>$refer);
    my $res = $HTTP->get($URL,"referer"=>$refer);
#    use Data::Dumper;print STDERR Dumper($res);
    my $data;
    my $result;
    if($res->is_success) {
        my $code = $res->content;
        if($code and $code =~ m/dyn\.setResults\((.+?)\)\s*\;\s*\</s) {
            $code = $1;
        }
        $data = eval($code);
      #  use Data::Dumper;print STDERR Dumper($data);
        if($!) {
            $result=[-1,$!,$data],
        }
        elsif(ref $data) {
            $data = _make_data($data,$data_id);
#        use Data::Dumper;print STDERR Dumper($data);
            $result=[200,grep_size($args{match_size},$data->{$data_id}),$data],
        }
        else {
            $result=[-2,$data,$data];
        }
    }
    else {
        $result=[$res->code,$res->status_line];
    }
    if($self and ref $self) {
        $self->{data}=$result->[0];
        $self->{results}=$result->[1];
    }
    return @{$result};
}

sub extract_url {
    my $result = shift;
    return $result->{url};
}

sub search_images {
    my $self = shift;
    if($self and ref $self) {
        return $self->search("images",DATA_ID,IMAGE_SEARCH_REFER,@_);
        
    }
    else {
        unshift @_,$self;
        return &search("images",DATA_ID,IMAGE_SEARCH_REFER,@_);
   } 
}





1;
