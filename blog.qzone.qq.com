#!/usr/bin/perl
use strict;
use Encode;
use LWP::UserAgent;
use HTTP::Request;
my $gb = Encode::find_encoding("gbk");
my $utf = Encode::find_encoding("utf8");
my $HOST="http://b.qzone.qq.com";
my $HOSTCGI="$HOST/cgi-bin/blognew";
my $REFERER= "http://cm.qzs.qq.com/qzone/";

my $http = LWP::UserAgent->new("agent"=>"Mozilla/5.0");


my $UIN;


sub get_url {
    my $url=shift;
    return undef unless($url);
    print STDERR "Requesting $url ...\n";
    my $res = $http->get($url,"referer"=>$REFERER);
    if($res->is_success) {
        return $res->content;
    }
    else {
        print $res->status_line;
        return undef;
    }
    return 
}

sub blog_output_titlelist {
    my ($uin,$from,$count) = @_;
    $uin = $UIN unless($uin && $uin>0);
    $from = 1 unless($from && $from>0);
    $count = 15 unless($count && $count>0);
    my $url = "$HOSTCGI/blog_output_titlelist?uin=$uin&vuin=0&property=GoRE&getall=1&styledm=cm.qzonestyle.gtimg.cn&imgdm=cm.qzs.qq.com&bdm=b.qzone.qq.com&category=&num=$count&sorttype=0&arch=0&from=$from";
    return $gb->decode(&get_url($url));
}

sub blog_output_data {
    my($blogid,$uin) = @_;
    $uin = $UIN unless($uin);
    my $url = "$HOSTCGI/blog_output_data?uin=$uin&blogid=$blogid&styledm=cm.qzonestyle.gtimg.cn&imgdm=cm.qzs.qq.com&bdm=b.qzone.qq.com&mode=2&numperpage=15";
    return $gb->decode(&get_url($url));
}

sub js_object_hash {
    return @_;
}
#print &blog_output_data('1270205023','185196590');

print &blog_output_titlelist('185196590',1,20);


