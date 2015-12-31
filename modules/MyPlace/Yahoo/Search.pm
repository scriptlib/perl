#!/usr/bin/perl -w
package MyPlace::Yahoo::BOSS;
use JSON;
use LWP::UserAgent;
use constant {
    APPID=>'BlVF2czV34FVChK2mzsN7SBghcl.NwZ4YayhlbBXiYxPnRScC49U1ja4HnnF',
    YAHOO_URL_SEARCH_IMAGES=>'http://images.search.yahoo.com/search/',
    URL_ID=>'url',
    DEFAULT_COUNT=>20,
    MAX_COUNT=>50,
};

my @VALID_PARAMS = qw/
    appid
    start
    count
    filter
    lang
    region
    format
    callback
    sites
    type
    referurl
    dimensions
    format
    view
    style
/;

my $HTTP;

sub get_api_url {
    my ($vertical,$query,%params) = @_;
    $params{appid}=APPID unless($params{appid});
    my %valid_params;
    foreach(@VALID_PARAMS) {
        $valid_params{$_} = $params{$_} if($params{$_});
    }
    my $params = join("&",map ("$_=" . $params{$_},keys %valid_params));
    return "http://boss.yahooapis.com/ysearch/$vertical/v1/$query?$params";
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
sub search {
    my $self = shift;
    unshift @_,$self unless($self and ref $self);
    my($ajax,$data_id,$refer,$keyword,%args)=@_;
    if($args{count}) {
        $args{count}=MAX_COUNT if($args{count}>50);
    }
    else {
        $args{count}=DEFAULT_COUNT;
    }
    my $URL = &get_api_url($ajax,$keyword,%args);
    print STDERR "Retriving $URL...\n";
    $HTTP = LWP::UserAgent->new() unless($HTTP);
    my $res = $HTTP->get($URL,"referer"=>$refer);
    my $data;
    my $result;
    if($res->is_success) {
        $data = from_json($res->content);
        $data = $data->{ysearchresponse};
#            use Data::Dumper;print STDERR Dumper($data);
        if($data->{'responsecode'} == 200 and $data->{$data_id}) {
            $data->{$data_id} = grep_size($args{match_size},$data->{$data_id});
        }
        else {
            $data->{$data_id}="No result.";
        }
        $result=[$data->{responsecode},$data->{$data_id},$data];
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
        return $self->search("images","resultset_images",YAHOO_URL_SEARCH_IMAGES,@_);
        
    }
    else {
        unshift @_,$self;
        return &search("images","resultset_images",YAHOO_URL_SEARCH_IMAGES,@_);
   } 
}





1;
