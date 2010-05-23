#!/usr/bin/perl -w
package MyPlace::Google;
use JSON;
use LWP::UserAgent;
use constant {
    GOOGLE_AJAX_SEARCH_IMAGES =>
    'http://ajax.googleapis.com/ajax/services/search/images',
    GOOGLE_URL_SEARCH_IMAGES =>
    'http://www.google.com/imghp',
    LARGE_RESULT => 8,
    SMALL_RESULT => 4,
};
my $HTTP;

sub new {
    my $class = shift;
    return bless {@_},$class;
}

sub search {
    my $self = shift;
    unshift @_,$self unless($self and ref $self);
    my($ajax,$refer,%args)=@_;
    $HTTP = LWP::UserAgent->new() unless($HTTP);
    my $params = join("&",map ("$_=" . $args{$_},keys %args));
    my $URL = "$ajax?$params";
    my $res = $HTTP->get($URL,"referer"=>$refer);
    my $data;
    my $result;
    if($res->is_success) {
        $data = from_json($res->content);
        if($data->{'responseStatus'} == 200) {
            $result=[$data,$data->{'responseData'}->{results}];
        }
        else {
            $result=[$data->{'responseStatus'},"No results"];
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

sub search_images {
    my $self = shift;
    if($self and ref $self) {
        return $self->search(GOOGLE_AJAX_SEARCH_IMAGES, GOOGLE_URL_SEARCH_IMAGES,@_);
        
    }
    else {
        unshift @_,$self;
        return &search(GOOGLE_AJAX_SEARCH_IMAGES, GOOGLE_URL_SEARCH_IMAGES,@_);
   } 
}

1;
