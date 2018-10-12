#!/usr/bin/perl -w
package MyPlace::Douyin;
use strict;
use warnings;
use MyPlace::Curl;
use MyPlace::URLRule::Utils qw/extract_title/;
use MyPlace::String::Utils qw/from_xdigit/;
BEGIN {
    require Exporter;
    our ($VERSION,@ISA,@EXPORT,@EXPORT_OK,%EXPORT_TAGS);
    $VERSION        = 1.00;
    @ISA            = qw(Exporter);
    @EXPORT         = qw();
    @EXPORT_OK      = qw(get_posts_from_url get_url get_info get_posts get_amemv_api get_favs);
}
my $private_curl;
#my $cookie = $ENV{HOME} . "/.curl_cookies.dat";
sub get_curl {
	if(not $private_curl) {
		$private_curl = MyPlace::Curl->new(
			'user-agent'=>'Mozilla/5.0 (Android 9.0; Mobile; rv:61.0) Gecko/61.0 Firefox/61.0',
			"location"=>'',
			"silent"=>'',
			"show-error"=>'',
			#"cookie"=>$cookie,
			"max-time"=>180,
			#"progress-bar"=>'',
		);
	}
	return $private_curl;
}
sub get_url {
	my $c = &get_curl;
	my $url = shift;
	print STDERR "[Retriving] $url ..\n";
	my ($ok,$data) = $c->get($url,@_);
	return $data;
}
#https://www.iesdouyin.com/aweme/v1/aweme/post/?user_id=102673338020&count=21&max_cursor=0&aid=1128&_signature=txNgexAf7JgXgrtArv3yKbcTYG&dytk=f80db17895af6fc4615fa0e1176b2e34

my %p_id_maps = (
	user=>"uid",
	user_id=>"uid",
	userName=>"uname",
	#	authorName=>"uname",
	user_name=>"uname",
	"user-info-id"=>"dyid",
	"user-info-name"=>"uname",
	nickname=>"uname",
	shortid=>"dyid",
);

sub get_info {
	my $html = get_url(@_);
	my %i;
	while($html =~ m/\s+([^'"\s:]+):\s*['"]([^'"]+)['"]/g) {
		$i{$1} = $2;
	}
	my $url = shift;
	while($url =~ m/(?:\/([^\/]+)\/|[&\?]([^&\?=]+)=)(\d+)/g) {
		$1 ? $i{$1} = $3 : $i{$2} = $3;
	}
	while($html =~ m/<p[^>]+class="(user-[^"]+|nickname|shortid)"[^>]*>(.+?)<\/p>/g) {
		my $k = $1;
		my $v = $2;
		$v =~ s/\s+//g;
		$v =~ s/<[^>]+>//g;
		$i{$k} = $v;
	}
	if($html =~ m/<video[^>]+src="([^"]+)/) {
		$i{video} = $1;
	}
	if($html =~ m/<inpu[^>]+value="([^"]+\/large\/[^\/]+\.jpg)/) {
		push @{$i{images}},$1;
	}
	foreach(keys %p_id_maps) {
		my $id = $p_id_maps{$_};
		next unless($i{$_});
		if(not $i{$id}) {
			$i{$id} = $i{$_};
		}
		delete $i{$_};
	}
	#	my $u8 = Encode::find_encoding("utf-8");
	foreach(qw/uname/) {
		next unless($i{$_});
		$i{$_} =~ s/^\@//;
		$i{$_} = &extract_title($i{$_});
	}
	if($i{dyid}) {
		$i{dyid} = &from_xdigit($i{dyid});
	}
	$i{host} = "douyin.com";
	$i{profile} = $i{uid};
	$i{user_id} = $i{uid};
	$i{aweme_id} = $i{itemId};
	my %s = (
		%i,
		posts=>[{%i}],
	);
	return %s;
}

sub get_amemv_api {
	my %p;
	my $type = shift;
	$p{user_id} = shift(@_) || "";
	$p{dytk} = shift(@_) || "";
	$p{max_cursor} = shift(@_) || 0;
	$p{count} = shift(@_) || 21;
	my $base = "https://www.amemv.com/aweme/v1/aweme/$type/?";
	my @params;
	foreach my $k(keys %p) {
		push @params,"$k=$p{$k}";
	}
	return $base . join("&",@params);
}

sub get_posts {
	#https://www.iesdouyin.com/aweme/v1/aweme/post/?user_id=102673338020&count=21&max_cursor=0&aid=1128&_signature=wohv9RAcmRpiGbTO5.81UMKIb-&dytk=f80db17895af6fc4615fa0e1176b2e34	
	return get_posts_from_url(get_amemv_api("post",@_));
}
sub get_favs {
	#https://www.amemv.com/aweme/v1/aweme/favorite/?user_id=102673338020&count=21&aid=1128&_signature=wohv9RAcmRpiGbTO5.81UMKIb-&dytk=f80db17895af6fc4615fa0e1176b2e34	
	return get_posts_from_url(get_amemv_api("favorite",@_));
}

sub get_posts_from_url {
	my $url = shift;
	my $html = get_url($url);
    my @html = split(/"text_extra"/,$html);
	my $top = $html[0];
	my %info = (posts=>[]);
	if($url =~ m/user_id=(\d+)/) {
		$info{user_id} = "$1";
	}
	else {
		$info{user_id} = "000000000000";
	}
	while($top =~ m/"([^"]+)"\s*:\s*(\d+)/g) {
		$info{$1}=$2;
	}
	foreach(@html) {
		my %v = (images=>[]);
		while(m/"([^"]+)"\s*:\s*(\d+)/g) {
			$v{$1}=$2;
			if($1 eq 'max_cursor') {
				$info{max_cursor} = $2;
			}
		}
		while(m/"([^"]+)"\s*:\s*["']([^'"]+)/g) {
			$v{$1}=$2;
		}
		if(m/"([^"]+\?video_id=[^&]+)/) {
			$v{video} = $1;
		}
		while(m/"([^"]+\.jpg)/g) {
			push @{$v{images}},$1;
		}
		push @{$info{posts}},\%v;
	}
	return %info;
}
1;
__END__
