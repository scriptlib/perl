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
    IMAGE_DEFAULT_COUNT=>18,
    IMAGE_MAX_COUNT=>18,
    IMAGE_DATA_ID=>'results',
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
my %DEFAULT_PARAMS = 
(
    www => {},
    images => 
    {
        'safe'=>'off',
        'hl'=>'en',
    },
);

my %IMAGE_DMS_MAP = (
        '>400x300'=>'qsvga',
        '>640x480'=>'vga',
        '>800x600'=>'svga',
        '>1024x768'=>'xga',
        '>1600x1200'=>'2mp',
        '>2272x1704'=>'4mp',
        '>2816x2112'=>'6mp',
        '>3264x2448'=>'8mp',
        '>3648x2736'=>'10mp',
        '>4096x3072'=>'12mp',
        '>4480x3360'=>'15mp',
        '>5120x3840'=>'20mp',
        '>7216x5412'=>'40mp',
        '>9600x7200'=>'70mp',
);

my $HTTP;

sub get_google_ip {
   return $GOOGLE_IP[int(rand(@GOOGLE_IP))]; 
}

sub get_api_url {
    my ($vertical,$keyword,$page,%params) = @_;
    my %api_params;
    foreach (keys  %params) {
        next if($_ eq 'type');
        next if($_ eq 'dimensions');
        next if($_ eq 'size');
        if($_ eq 'filter') {
            $api_params{safe} = $params{$_} eq 'no' ? 'off' : 'on';
        }
        elsif($_ eq 'lang' or $_ eq 'region') {
            $api_params{hl} = $params{$_};
        }
        else {
            $api_params{$_} = $params{$_}; 
        }
    }
    if($vertical eq 'images') {
        if($params{dimensions}) {
            $api_params{tbs}='isch:1,isz:lt,islt:' . $params{dimensions};
        }
        elsif($params{size} and $IMAGE_DMS_MAP{$params{size}}) {
            $api_params{tbs}='isch:1,isz:lt,islt:' . $IMAGE_DMS_MAP{$params{size}};
        }
        elsif($params{type}) {
            $api_params{imgsz}=$params{type};
        }
        $api_params{ndsp} = IMAGE_DEFAULT_COUNT;
    }
    if(!$api_params{q}) {
        $api_params{q} = $keyword;
    }
    if(!$api_params{start}) {
        if($page and $page =~ m/^[0-9]+$/ and $page>1) {
            $api_params{start} = $api_params{ndsp} * ($page - 1);
        }
    }
    $api_params{hl} = 'en' unless($api_params{hl});
    $api_params{safe} = 'off' unless($api_params{safe});
    my $params = join("&",map ("$_=" . $api_params{$_},keys %api_params));
    return 'http://' . &get_google_ip()  . "/$vertical?$params";
}

sub new {
    my $class = shift;
    return bless {@_},$class;
}

sub _make_data {
    my $org = shift;
    my @result;
    return \@result unless($org and @{$org});
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
        if($_->[9] =~ /(\d+)\s*\&times;\s*(\d+)\s*-\s*(\d+[kKmM]?)/) {
            $cur{width}=$1;
            $cur{height}=$2;
            $cur{size}=$3;
        }
        push @result,\%cur;
    }
    return \@result;
}
sub search {
    my $self = shift;
    unshift @_,$self unless($self and ref $self);
    my($ajax,$data_id,$refer,$keyword,$page,%args)=@_;
    my $URL = &get_api_url($ajax,$keyword,$page,%args);
    print STDERR "Retrieving $URL ...";
    if(!$HTTP) {
        $HTTP = LWP::UserAgent->new();
        $HTTP->agent("Mozilla/5.0 (X11; U; Linux i686; en-US; rv:1.9.0.3) Gecko/2008092416 Firefox/3.0.3 Firefox/3.0.1");
    }
    my $res = $HTTP->get($URL,"referer"=>$refer);
    print STDERR " [",$res->code,"]\n";
    my $data;
    my $results;
    my $status;
    if($res->is_success) {
        my $code = $res->content;
        if($code and $code =~ m/dyn\.setResults\((.+?)\)\s*\;\s*\</s) {
            $code = $1;
        }
        $data = eval($code);
    #    use Data::Dumper;print Dumper($data);
        if(ref $data) {
            $results = _make_data($data);
            $status = 1;
        }
        elsif($!) {
            $status = -1;
            $results = $!;
            $data = $code;
        }
        else {
            $status = -2;
            $results = $data;
            $data = $code;
        }
    }
    else {
        $status = undef;
        $results = $res->code . " " . $res->status_line;
    }
    if($self and ref $self) {
        $self->{keyword}=$keyword;
        $self->{ajax} = $ajax;
        $self->{refer}=$refer;
        $self->{args} = \%args;
        $self->{status}=$status;
        $self->{data}=$data;
        $self->{results}=$results;
    }
    return $status,$results,$data;
}

sub extract_url {
    my $result = shift;
    return $result->{url};
}

sub search_images {
    my $self = shift;
    if($self and ref $self) {
        return $self->search("images",IMAGE_DATA_ID,IMAGE_SEARCH_REFER,@_);
        
    }
    else {
        unshift @_,$self;
        return &search("images",IMAGE_DATA_ID,IMAGE_SEARCH_REFER,@_);
   } 
}





1;
