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
	while($html =~ m/<(p|span)[^>]+class="(user-[^"]+|nickname|shortid|signature|location)"[^>]*>(.+?)<\/(\1)>/g) {
		my $k = $2;
		my $v = $3;
		$v =~ s/\s+//g;
		$v =~ s/<[^>]+>//g;
		$i{$k} = $v;
	}
	if($html =~ m/<img[^>]+class="avatar[^>]+src="([^"]+)/) {
		$i{avatar} = $1;
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
		$i{dyid} =~ s/.*://;
		$i{dyid} = &extract_title($i{dyid});
		$i{dyid} =~ s/\s+//g;
	}
	$i{host} = "douyin.com";
	$i{profile} = $i{uid};
	$i{user_id} = $i{uid};
	$i{aweme_id} = $i{itemId};
	$i{uname} = $i{uname} || $i{dyid} || $i{uid};
	$i{id2} = $i{dyid};
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
	#my $base = "https://www.amemv.com/aweme/v1/aweme/$type/?";
	my $base = "https://crawldata.app/api/douyin/v1/aweme/$type?";
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

use JSON qw/decode_json/;
sub safe_decode_json {
	my $json = eval { decode_json($_[0]); };
	if($@) {
		print STDERR "Error deocding JSON text:$@\n";
		$@ = undef;
		return {};
	}
	else {
		if($json->{reason}) {
			print STDERR "Error: " . $json->{reason},"\n";
		}
		return $json;
	}
}

sub get_posts_from_url {
	my $url = shift;
	$url =~ s/^.*\/([^\/]+)\/\?([^\/]+)$/http:\/\/crawldata.app\/api\/douyin\/v1\/aweme\/$1?$2/;
	my $html = get_url($url);
	my $json = safe_decode_json($html);
	if(!$json->{data}) {
		return (
			error=>"Error decoding JSON text",
		);
	}
	#use Data::Dumper;
	#print STDERR Data::Dumper->Dump([$json->{data}->{aweme_list}->[0]],["\$json"]),"\n";
	my %info;
	if($url =~ m/user_id=(\d+)/) {
		$info{user_id} = "$1";
	}
	else {
		$info{user_id} = "000000000000";
	}
	foreach(qw/min_cursor max_cursor has_more/) {
		$info{$_} = $json->{data}->{$_};
	}
	return %info unless($json->{data}->{aweme_list});
	my @posts = @{$json->{data}->{aweme_list}};
	foreach my $P (@posts) {
		my %v = ();
		foreach my $k (qw/desc author_user_id aweme_id create_time/) {
			$v{$k} = $P->{$k} if($P->{$k});
			$v{$k} = $P->{video}->{$k} if($P->{video}->{$k});
			#	print STDERR "$k => $v{$k}\n";
		}
		local $_ = $P->{video};
		foreach my $k (qw/origin_cover cover_hd cover_large cover_medium cover_thumb/) {
			if($_->{$k}->{url_list}) {
				foreach my $u (@{$_->{$k}->{url_list}}) {
					push @{$v{images}},$u;
				}
				last;
			}
		}
		foreach my $k (qw/play_addr play_addr_lowbr download_addr/) {
			my $u = $_->{$k}->{uri};
			if($u) {
				$v{video} = 'https://aweme.snssdk.com/aweme/v1/play/?video_id=' . $u;
				last;
			}
		}
		push @{$info{posts}},\%v;
	}
	return %info;
}
1;
__END__
