#!/usr/bin/perl
use strict;
use Encode;
use LWP::UserAgent;
use HTTP::Request;
my $http = LWP::UserAgent->new("agent"=>"Mozilla/5.0");

my $url = shift;
my $encoding = shift;
die("Usage:$0 URL [Encoding] [HTTP HEADERS...]\n") unless($url);

if($encoding) {
    $encoding = find_encoding($encoding);
}

$url = "http://$url" unless($url =~ /^http:\/\//i);
print STDERR "Requesting $url ...\n";
my $res = $http->get($url,"referer"=>$url,@ARGV);
if($res->is_success) {
    print STDOUT $encoding ? $encoding->decode($res->content) : $res->content;
}
else {
    print STDERR $res->status_line;
}


