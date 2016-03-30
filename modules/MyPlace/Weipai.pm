#!/usr/bin/perl -w
package MyPlace::Weipai;
use strict;
use warnings;
BEGIN {
    require Exporter;
    our ($VERSION,@ISA,@EXPORT,@EXPORT_OK,%EXPORT_TAGS);
    $VERSION        = 1.00;
    @ISA            = qw(Exporter);
	#@EXPORT		    = qw(profile user videos home square get_likes fans follows video);
    @EXPORT_OK      = qw(extract_title build_url profile user videos home square get_likes fans follows video get_url safe_decode_json);
}

our $HOST = 'http://w1.weipai.cn';
our %URLSTPL = (
	profile=>'/get_profile?&weipai_userid=$1',
	user=>'/home_user?relative=after&user_id=$1&day_count=$2&cursor=$3',
	videos=>'/home_user?relative=after&user_id=$1&day_count=$2&cursor=$3',
	video=>'/user_video_list?blog_id=$1',
	my_home=>'/my_follow_user_video_list?relative=after&user_id=$1&count=$2&cursor=$3',
	square=>'/top_video?relative=after&type=$1&count=$2&cursor=$3',
	my_likes=>'/my_favorite_video_list?count=$2&relative=after&user_id=$1&cursor=$3',
	fans=>'/user_fans_list?count=$2&relative=after&uid=$1&cursor=$3',
	follows=>'/user_follow_list?count=$2&relative=after&uid=$1&cursor=$3',
	likes=>'/user/compresseduserlikes?count=$2&cursor=$3&relative=after&user_id=$1',
	search_user=>'/search_user?count=$2&next_cursor=$3&relative=after&keyword=$1',
	search_video=>'/search_video?count=$2&next_cursor=$3&relative=after&keyword=$1',
	video_defender=>'/top_defender?count=$2&relative=after&vid=$1&next_cursor=$3',
	defender=>'/top_defender?count=$2&relative=after&uid=$1&next_cursor=$3',
	play=>'/play_video?user_id=508775398134943b58000051&blog_id=$1',
	comment=>'/blog_comment_list?count=$2&relative=after&blog_id=$1',
	share=>'/get_template?template_type=third_share_qq&blog_id=$1',
);
our %PRINT_FORMAT = (
	'defender' => {
		result=>'defender_list',
		format=>"%s\t%s\n",
		keys=>[qw/uid nickname/],
	},
	'follows' => {
		result=>'user_list',
		format=>"%003d %s\t%s\t\t%s\n",
		keys=>[qw/video_num user_id nickname intro/],
	},
);

use JSON qw/decode_json/;
use Encode qw/find_encoding/;
use MyPlace::Curl;
use utf8;
my $CURL = MyPlace::Curl->new(
	"location"=>'',
	"silent"=>'',
	"show-error"=>'',
#	"retry"=>4,
	"max-time"=>120,
);

my $COPIED_HEADER = '
Content-Length: 85
Content-Type: application/x-www-form-urlencoded
Host: w1.weipai.cn
Connection: Keep-Alive
User-Agent: android-async-http/1.4.3 (http://loopj.com/android-async-http)
Accept-Encoding: gzip
Phone-Type: android_Lenovo A788t_4.3
os: android
Channel: 360%E6%89%8B%E6%9C%BA%E5%8A%A9%E6%89%8B
App-Name: weipai
Api-Version: 8
Weipai-Token: ef1d3ac6f047b95dc8efe19a9439210804020274e9c4feddc94c60f9182a23318db7a8715127a3b9
Phone-Number: 
Com-Id: weipai
sign: d18b74787b5683193d8d89f9009407cc
time: 1459347429
Client-Version: 1.0.0.0
Weipai-Userid: 508775398134943b58000051
Device-Uuid: 53ede2300d89c4cd99b4d92d198affcaf5d63101
Latitude: 23.548452
Longitude: 116.409982
Push-Id: com.weipai.weipaipro
Kernel-Version: 15
count=20&relative=&compressd=1&day_count=7&nickname=&user_id=508775398134943b58000051
';
my @CURLOPT;# = ('--compressed');
foreach(split(/\s*\n\s*/,$COPIED_HEADER)) {
	next unless($_);
	next unless(m/:/);
	s/^([^:]+):\s+/$1:/;
	next if(m/(?:Content-Length|Host|Connection|Accept-Encoding|sign|time):/);
#	print STDERR $_,"\n";
	push @CURLOPT,'-H',$_;
}
#LAST HEADER UPDATED 2015/09/20



my $utf8 = find_encoding('utf8');

my $DATABASE_FILE = '/myplace/workspace/perl/urlrule/sites/weipai.cn/database.sq';
my %NAMES;
my %IDS;
if(open FI,"<",$DATABASE_FILE) {
	while(<FI>) {
		chomp;
		if(m/^\s*([^\t]+)\s+(.+?)\s*$/) {
			$NAMES{$2} = $1;
			$IDS{$1} = $2;
		}
	}
	close FI;
}

sub WRITE_DATABASE {
	my $id = shift;
	my $name = shift;
	if($IDS{$id}) {
		print STDERR " <$DATABASE_FILE>:\n ID already defined:\n$id\t$IDS{$id}\n\n";
		return undef;
	}
	if(open FO,">>",$DATABASE_FILE) {
		print STDERR "Writting to $DATABASE_FILE ...\n";
		print FO join("\t",@_),"\n";
		close FO;
	}
}

sub extract_title {
	my $title = shift;
	return unless($title);
	$title =~ s/\@微拍小秘书//g;
	$title =~ s/”//g;
	$title =~ s/<[^.>]+>//g;
	$title =~ s/\/\?\*'"//g;
	$title =~ s/&amp;amp;/&/g;
	$title =~ s/&amp;/&/g;
	$title =~ s/&hellip;/…/g;
	$title =~ s/&[^&]+;//g;
#	$title =~ s/\x{1f60f}|\x{1f614}|\x{1f604}//g;
#	$title =~ s/[\P{Print}]+//g;
#	$title =~ s/[^\p{CJK_Unified_Ideographs}\p{ASCII}]//g;
	$title =~ s/[^{\p{Punctuation}\p{CJK_Unified_Ideographs}\p{CJK_SYMBOLS_AND_PUNCTUATION}\p{HALFWIDTH_AND_FULLWIDTH_FORMS}\p{CJK_COMPATIBILITY_FORMS}\p{VERTICAL_FORMS}\p{ASCII}\p{LATIN}\p{CJK_Unified_Ideographs_Extension_A}\p{CJK_Unified_Ideographs_Extension_B}\p{CJK_Unified_Ideographs_Extension_C}\p{CJK_Unified_Ideographs_Extension_D}]//g;
#	$title =~ s/[\p{Block: Emoticons}]//g;
	#print STDERR "\n\n$title=>\n", length($title),"\n\n";
	$title =~ s/\s{2,}/ /g;
	$title =~ s/[\r\n\/\?:\*\>\<\|]+/ /g;
	$title =~ s/_+$//;
	my $maxlen = 70;
	if(length($title) > $maxlen) {
		$title = substr($title,0,$maxlen);
	}	
	$title =~ s/^\s+//;
	$title =~ s/\s+$//;
	$title = $utf8->encode($title);
	return $title;
}

sub get_url {
	my $url = shift;
	my $method = 'get';
	my $verbose = shift(@_) || '-v';
	if($verbose eq '--get') {
		$method = 'get';
		$verbose = shift(@_) || '-v';
	}
	my $json = shift;
	my $silent;

	my $retry = 4;
	return undef unless($url);

	if(!$verbose) {
	}
	elsif('-q' eq "$verbose") {
		$verbose = undef;
		$silent = 1;
	}
	elsif('-v' eq "$verbose") {
		$verbose = 1;
		$silent = undef;
	}
	else {
		unshift @_,$verbose;
		$verbose = undef;
		$silent = undef;
	}

	my $data;
	my $status = 1;
	print STDERR uc("[$method]") . " $url ..." if($verbose);
	while($retry) {
		if($method eq 'get') {
			#		print STDERR join("\n",@CURLOPT,"\n");
			($status,$data) = $CURL->get($url,@CURLOPT,'-H','time:' . time);
		}
		else {
			my $posturl = $url;
			my $content = '';
			if($posturl =~ m/^(.+)\?(.+)$/) {
				$posturl = $1;
				$content = $2;
			}
			($status,$data) = $CURL->postd($posturl,$content,@CURLOPT,'-H','time:' . time);

		}
		if($status != 0) {
		}
		elsif(!$data) {
		}
		elsif($json) {
			last if($data =~ /^\s*\{/);
			last if($data =~ /\s*\}\s*;?\s*$/);
		}	
		else {
			last;
		}
		print STDERR "\t[FAIELD $status]\n[Retry " . (5 - $retry) . "] $url ..." if($verbose);
		$retry--;
		sleep 3;
	}
	if($status != 0 ) {
		print STDERR "\t[FAILED $status]\n" unless($silent);
		return undef;
	}
	else {
		print STDERR "\t[OK]\n" unless($silent);
		return $data;
	}
}
sub get_html_url {
	my $url = shift;
	print STDERR "Retriving $url ...\n";
	my($exitval,$data) = $CURL->get($url,@_);
	if($exitval) {
		return undef;
	}
	else {
		return $data;
	}
}

sub build_url {
	my $tpl = shift;
	my $count = 0;
	my $url = $HOST . $URLSTPL{$tpl};
	#print STDERR join(", ", @_),"\n";
	foreach(@_) {
		next unless($_);
		next unless(m/\//);
		my $new;
		if(m/([^\/]+)\/?$/) {
			$new = $1;
		}
		elsif(m/([^\/]+)\/?/) {
			$new = $1;
		}
		if($new) {
			print STDERR "$_ => $new\n";
			$_ = $new;
		}
	}
	if($tpl =~ m/^(?:profile|user|video|my_home|my_likes|fans|follows|likes)$/ and $_[0] and $_[0] !~ /^(?:\d[\da-z]{23})$/)  {
		my $name = $_[0];
		my $id = $_[0];
		if($NAMES{$name}) {
			$id = $NAMES{$name};
			printf STDERR "\n[MATCH] %003d> %s %s\n",0,$id,$name;
		}
		else {
			my $r = get_data('search_user',$_[0]);
			if($r->{state} and $r->{user_list}) {
				foreach my $u (@{$r->{user_list}}) {
					if($u->{nickname} eq $_[0]) {
						printf STDERR "\n[MATCH] %003d> %s %s\n",$u->{video_num},$u->{user_id},$u->{nickname};
						$id = $u->{user_id};
						$NAMES{$name} = $id;
						WRITE_DATABASE($id,$name);
						last;
					}
					else {
						printf STDERR "[SKIP] %003d> %s %s\n",$u->{video_num},$u->{user_id},$u->{nickname};
					}
				}
			}
		}
		$_[0] = $id;
	}
	foreach(@_) {
		$count++;
		if(defined($_)) {
			$url =~ s/\$$count/$_/g;
		}
		else {
			$url =~ s/[^\?\&=]+=\$$count&?//g;
		}
	}
	if($count < 10) {
		my $range = "[" . $count . "-9]";
		$url =~ s/[^\?\&=]+=\$$range&?//g;
	}
	$url =~ s/\?&/\?/;
	$url =~ s/&$//;
	return $url;
}

sub _encode {
	my $data = shift;
	my $type = ref $data;
	if(!$type) {
		return $utf8->encode($data);
	}
	elsif($type eq 'ARRAY') {
		foreach (@$data) {
			$_ = _encode($_);
		}
		return $data;
	}
	elsif($type eq 'HASH') {
		foreach my $key (keys %$data) {
			$data->{$key} = _encode($data->{$key});
		}
		return $data;
	}
}

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

sub get_json {
	return safe_decode_json(get_url(build_url(@_),undef,1));
}

sub search_user {
	my $name = shift;
	my $page = shift(@_) || 1;
	my $r = get_data('search_user',$name,20,($page - 1)*20);
	return $r;

	my $url = "http://www.weipai.cn/search/more/t/user/q/$name?page=$page";
	my $html = get_html_url($url);
	my %r;
	return \%r unless($html);
	while($html =~ m/href="\/user\/([^\/]+)"[^>]+class="name"[^>]+title="([^"]+)/g) {
		$r{state} = 1;
		push @{$r{user_list}},{
			user_id=>$1,
			nickname=>$2,
		};
	}
	return \%r;
}
sub get_data {
	my $what = shift;
	my $cmd = lc($what);
	my $url;
	my $data;
	if($cmd eq 'videoinfo') {
		my $video = safe_decode_json(get_url(build_url('video',@_),undef,1));
		$video = $video->{video_list}->[0] if($video->{video_list});
		delete $video->{defender_list};
		delete $video->{top_reply_list};
		$data = $video;
	}
	elsif($cmd eq 'poster') {
		my $videoid = shift;
		my $video = safe_decode_json(get_url(build_url('video',$videoid),undef,1));
		if($video->{video_list}) {
			my $uid = $video->{video_list}->[0]->{user_id};
			print STDERR "USERID => $uid\n"; 
			$data = safe_decode_json(get_url(build_url('user',$uid,@_),undef,1));
			$data->{profile} = get_json('profile',$uid);
			delete $data->{defender_list};
		}
		else {
			$data = $video;
		}
	}
	else {
		$url = build_url($cmd,@_);
		$data = safe_decode_json(get_url($url,undef,1));
	}
	return _encode($data);
}


sub get_user {
	my $uid = shift;
	return get_data('user',$uid,1);
}

sub extract_info {
	my $url = shift;
	my $uid;
	my $vid;
	if($url =~ m/^http:\/\/www\.weipai\.cn\/(?:user|videos|follows|fans)\/([^\/\s%&]+)/) {
		$uid = $1;
	}
	elsif($url =~ m/weipai\.cn\/(?:share\/flash\/|video\/)([^\?\s%\_\&\#\/]+)/) {
		$vid = $1;
	}
	elsif($url =~ m/user_video_list\?[^\?]*blog_id=([^&\?\/"]+)/) {
		$vid = $1;
	}
	my $info;
	if($vid) {
		$info = get_data('video',$vid);
		if($info->{video_list}) {
			$info = clean_up_data($info->{video_list})->[0];
			$info->{uid} = $info->{user_id};
			$info->{uname} = $info->{nickname};
		}
	}
	elsif($uid) {
		$info = clean_up_data(get_data('user',$uid));
		$info->{uid} = $info->{user_id};
		delete $info->{user_id};
		$info->{uname} = $info->{nickname};
		delete $info->{nickname};
		delete $info->{diary_list};
	}
	else {
		$info = safe_decode_json(get_url($url,undef,1));
	}
	return $info;
}

sub get_user_from_page {
	my $url = shift;
	my %user;
	$url =~ s/weipai\.cn\/(?:videos|user)\//weipai.cn\/follows\//;
	my $data = get_html_url($url);
	my @text = split("\n",$data);
	foreach(@text) {
		chomp;
		if(!$user{username}) {
			if(m/class="name"[^>]*title="([^"]+)"/) {
				$user{username} = $1;
			}
			elsif(m/"nickname"\s*[:=]\s*"([^"]+)/) {
				$user{username} = $1;
				$user{username} =~ s/\\u(\w{4,4})/chr(hex($1))/eg;
			}
		}
		if(!$user{uid}) {
			if(m/href="\/user\/([^\/"]+)/) {
				$user{uid} = $1;
			}
			elsif(m/"user_id"\s*[:=]\s*"([^"]+)/) {
				$user{uid} = $1;
			}
		}
		last if($user{uid} and $user{usernmae});
	}
	if($user{uid}) {
		return \%user;
	}
	else {
		return undef;
	}
}

sub get_videos {
	my $uid = shift;
	my $days = shift(@_) || 7;
	my $cursor = shift;
	return get_data('user',$uid,$days,$cursor);
}

sub get_home {
	my $id = shift;
	my $count = shift(@_) || 40;
	my $cursor = shift;
	return get_data('home',$id,$count,$cursor);
}

sub get_square {
	my $type = shift(@_) || 'top_day';
	my $count = shift(@_) || 120;
	my $cursor = shift;
	return get_data('square',$type,$count,$cursor);
}

sub get_likes_by {
	my $what = shift;
	my $data = get_data($what,@_);
	$data->{video_list} ||= $data->{like_video_list};
	if($data->{video_list}) {
		foreach(@{$data->{video_list}}) {
			next unless(ref $_);
			$_->{video_id} ||= $_->{blog_id};
			$_->{video_play_url} ||= $_->{video_url};
		}
	}
	return $data;
}

sub get_likes {
	my $id = shift;
	my $count = shift(@_) || 40;
	my $cursor = shift;
	return get_likes_by('my_likes',$id,$count,$cursor);
}

sub get_all_likes {
	my $id = shift;
	my $limit = shift;
	my $count = 0;
	my $likes = get_likes($id,18);#->{video_list};
	my @result;
	while(1) {
		print Data::Dumper->Dump([$likes],['$likes']),"\n";
		if($likes->{video_list}) {
			my $v = clean_up_data($likes->{video_list});
			use Data::Dumper;
			push @result,@$v;
		}
		$count = scalar(@result);
		last unless($likes->{next_cursor});
		last if($limit and $count>$limit);
		$likes = get_likes($id,18,$likes->{next_cursor});
	}
	return @result;
}

sub get_fans {
	my $id = shift;
	my $count = shift(@_) || 40;
	my $cursor = shift;
	return get_data('fans',$id,$count,$cursor);
}
sub get_follows {
	my $id = shift;
	my $count = shift(@_) || 40;
	my $cursor = shift;
	return get_data('follows',$id,$count,$cursor);
}
sub get_video {
	my $id = shift;
	return get_data('video',$id);
}


sub get_user_videos {
	my $uid = shift;
	my $cursor = shift;
#	my $url = build_url('user',$uid,undef,$cursor);
	my %r;
	my $info = get_videos($uid,undef,$cursor);
	$r{uid} = $uid;
	$r{next_cursor} = $info->{next_cursor};
	my @video_list;
	$r{videos} = [];
	$r{count} = 0;
	my @data;
	if($info->{"diary_list"}) {
		foreach(@{$info->{"diary_list"}}) {
#"day": "2014-08-23",
#"city": "\u5e7f\u5dde\u5e02",
#"video_list": [{
#"blog_id": "53f87baea5640bff6b8b4576",
#"video_screenshot": "http:\/\/aliv.weipai.cn\/201408\/23\/19\/3C6C58A6-34DE-4D2B-9145-107BF7B70BB5.2.jpg",
#"video_intro": "\uff0c\u51bb\u6b7b\u4e86\u5728\u8001\u7238\u7684\u5e2e\u52a9\u4e0b\u5b8c\u6210\u4e86\u51b0\u6876\u6311\u6218@\u5fae\u62cd\u5c0f\u79d8\u4e66",
#"city": "\u5e7f\u5dde\u5e02"
#}]
			if($_->{video_list}) {
				push @video_list,$_->{video_list};
			}
		}
	}
	if($info->{user_video_list}) {
		push @video_list,$info->{user_video_list};
	}
	foreach(@video_list) {
		foreach my $videoinfo (@$_) {
			my $video = {};
			$video->{cover} = $videoinfo->{video_screenshot};
			$video->{video} = $video->{cover};
			$video->{video} =~ s/\.([^\/]+)$//;
#					$video->{title} = $utf8->encode($videoinfo->{video_intro});
			$video->{id} = $videoinfo->{blog_id};
			if($video->{cover} =~ m/\/(\d\d\d\d)(\d\d)\/(\d\d)\/(\d+)\//) {
				@{$video}{qw/year month day hour minute/} = ($1,$2,$3,$4,'');
			}
			push @{$r{videos}},$video;
			$r{count}++;
		}
	}
	return \%r;
}

#####################################################################
#
#                  CLASS IMPLEMENTION
#
#
#####################################################################


use base 'MyPlace::Program';
use Data::Dumper;

sub OPTIONS {
	qw/
	help|h
	manual
	dump|d
	user|u
	video|v
	format|for=n
	/;
}

sub clean_up_data {
	my $data = shift;
	my $type = ref $data;
	if(!$type) {
		return $data;
	}
	elsif($type eq 'ARRAY') {
		foreach my $item(@$data) {
			next unless(ref $item);
			clean_up_data($item,@_);
		}
	}
	elsif($type eq 'HASH') {
		foreach my $kw (qw/
				top_reply_list defender_list
				is_vip is_delete s_receive
				like_state video_play_num
				video_play_num video_like_num
				fans_user_list
		/,@_) {
			delete $data->{$kw};
		}
		foreach my $item(keys %$data) {
			clean_up_data($data->{$item},@_);
		}
	}
	return $data;
}

sub cmd_get_videos {
	my $opts = shift;
	my $uid = shift;
	my $cursor = shift;
	my $videos = get_user_videos($uid,$cursor);
	print Data::Dumper->Dump([$videos],[qw/$videos/]),"\n" if($opts->{dump});
	return $videos;
}

sub cmd_get_video {
	my $opts = shift;
	my $video = get_video(@_);
	$video = $video->{video_list}->[0] if($video->{video_list});
	delete $video->{defender_list};
	delete $video->{top_reply_list};
	print Data::Dumper->Dump([$video],[qw/$video/]),"\n" if($opts->{dump});
	return $video;
}

sub get_profile {
	my $id = shift;
#		$id =~ s/^.*\///;
#		$id =~ s/[\/\._].*$//;
		my %pro;
		foreach my $r (get_data('profile',$id),get_data('user',$id)) {
			if($r->{socialList}) {
				foreach my $k (@{$r->{socialList}}) {
					$r->{$k->{socialName} . "_profile"} = $k->{socialUrl};
				}
			}
			foreach my $k (qw/
					videoList hotImg
					socialList defender_list
					diary_list next_cursor
					prev_cursor level_des
					state 
					fans_user_list
					user_video_list
				/) {
				delete $r->{$k};
			}
			foreach my $k (keys %$r) {
				next unless(length($r->{$k}));
				$pro{$k} = $r->{$k};
			}
		}
	return \%pro;
}

sub show_profile {
	my $opt = shift;
	foreach my $id (@_) {
		my $pro = get_profile($id);
		print Data::Dumper->Dump([$pro],[$id]),"\n";
	}
	return 0;
}

sub save_profile {
	my $opt = shift;
	my $id = shift;
	my $pro = get_profile($id);
	if($pro->{avatar}) {
		system("download","--url",$pro->{avatar},"--saveas","$id.jpg");
	}
	if(open FO,'>',"$id.txt") {
		print FO Data::Dumper->Dump([$pro],[$id]),"\n";
		close FO;
	}
	else {
		print STDERR "Error opening $id.txt for writting: $!\n";
		return 1;
	}
	
}

sub show_follows {
	my $opt = shift;
	my $id = shift;
	my $limits = shift;
	my $count = 0;
	my @results;
		my $nc = undef;
		do {
			my $follows = get_follows($id,40,$nc);
			last unless($follows);
			#print STDERR Data::Dumper->Dump([$follows],['follows']),"\n";
			$nc = $follows->{next_cursor} || undef;
			foreach(@{$follows->{user_list}}) {
				$count++;
				if($limits and $limits < $count) {
					return 0;
				}
				print $_->{user_id},"\t",$_->{nickname},"\n";
			}
		} while($nc);
	return 0;
}

sub id {
		my $name = $_[0];
		my $id;
		if($NAMES{$name}) {
			$id = $NAMES{$name};
		}
		else {
			my $page = 0;
			my $r = search_user($_[0]);#get_data('search_user',$_[0]);
			while($r->{state} and $r->{user_list}) {
				foreach my $u (@{$r->{user_list}}) {
					if($u->{nickname} eq $_[0]) {
						$id = $u->{user_id};
						$NAMES{$name} = $id;
						WRITE_DATABASE($id,$name);
						return $id;
					}
					else {
					}
				}
				$page++;
				$r = search_user($_[0],$page);
			}
		}
		return $id;
}

sub extract {
	my $opt = shift;
	my $id = shift;
	my $cursor = shift;
}


sub MAIN {
	my $self = shift;
	my $opts = shift;
	my $command = shift;
	if(!$command) {
		return $self->USAGE;
	}
	$command = uc($command);

	if($command eq 'ID') {
		my $failed;
		foreach my $name(@_) {
			my $id = id($name);
			if($id) {
				print $id,"\t",$name,"\n";
			}	
			else {
				$failed = 1;
			}
		}
		return ($failed ? 1 : 0);
	}
	elsif($command eq 'GET_VIDEOS') {
		return cmd_get_videos($opts,@_);
	}
	elsif($command eq 'GET_VIDEO') {
		return cmd_get_video($opts,@_);
	}
	elsif($command eq 'PROFILE') {
		return show_profile($opts,@_);
	}
	elsif($command eq 'FOLLOWS') {
		return show_follows($opts,@_);
	}
	elsif($command eq 'SAVE-PROFILE') {
		return save_profile($opts,@_);
	}
	elsif($command eq 'EXTRACT') {
		return extract($opts,@_);
	}
	elsif($command eq 'LIKES') {
		my $info = get_likes(@_);
		print Data::Dumper->Dump([$info],['likes']),"\n";
	}
	elsif($command eq 'INFO') {
		my $info = extract_info(@_);
		print Data::Dumper->Dump([$info],['info']),"\n";
	}
	elsif($command eq 'DUMP') {
		my $what = shift;
		if(!$what) {
			print STDERR "Usage: $0 dump <user|video|fans|...> ...\n";
			return 1;
		}
		elsif($what eq 'all_likes') {
			print Data::Dumper->Dump([[get_all_likes(@_)]],['$likes']),"\n";
			return 0;
		}
		else {
			my $id = shift;
			$id =~ s/\/+$//;
			$id =~ s/^.*\///;
			#$id =~ s/[\/\._].*$//;
			my $r = get_data(lc($what),$id,@_);
			print Data::Dumper->Dump([$r],[$what]),"\n";
			return 0;
		}
	}
	elsif($command eq 'SEARCH') {
		if($opts->{video}) {
			my $result = get_data('search_video',@_);
			if($result->{state} and $result->{video_list}) {
				foreach my $v (@{$result->{video_list}}) {
					$v->{video_desc} =~ s/[\r\n\s]+/ /g;
					my $sp = 2;
					print STDOUT $v->{nickname}," ($v->{user_id}):\n";
					print STDOUT ' 'x(0 + $sp++),'<',$v->{video_like_num},'> ',$v->{video_id},"\n";
					print STDOUT ' 'x(0 + $sp++),$v->{video_url},"\n";
					print STDOUT ' 'x(0 + $sp++),$v->{video_desc},"\n\n";
				}
			}
			print STDOUT "\nNEXT_CURSOR:$result->{next_cursor}\n";
		}
		else {
			my $r = search_user(@_);
			if($r->{state} and $r->{user_list}) {
				foreach my $u (@{$r->{user_list}}) {
					if($opts->{format} and $opts->{format} == 1) {
						print $u->{user_id} . ">" . $u->{nickname} . "\n";
					}
					else {
						$u->{video_num} ||= '?';
						printf "%003s> %s %s\n",$u->{video_num},$u->{user_id},$u->{nickname};
					}
				}
			}
			print STDOUT "NEXT_CURSOR:$r->{next_cursor}\n" if($r->{next_cursor});
		}
		return 0;
	}
	elsif($command eq 'PRINT') {
		my $what = shift;
		if($what) {
			my $id = shift;
			$id =~ s/^.*\///;
			$id =~ s/[\/\._].*$//;
			my $r = get_data(lc($what),$id,@_);
			my $query = lc($what);
			if($PRINT_FORMAT{$what}) {
				my $fmt = $PRINT_FORMAT{$what};
				my @result = $fmt->{result} ? @{$r->{$fmt->{result}}} : @{$r};
				foreach my $item(@result) {
					printf $fmt->{format},@$item{@{$fmt->{keys}}},"\n";
				}
			}
			else {
				my @filters = ();
				if($query eq 'likes') {
					push @filters,qw/
						user_avatar video_reply_num video_screenshots_v
					/;
				}
				clean_up_data($r,@filters);
				print Data::Dumper->Dump([$r],[$what]),"\n";
			}
			return 0;
		}
		else {
			print STDERR "Usage: $0 print <user|video|fans|...> ...\n";
			return 1;
		}
	}
	elsif($command eq 'UUID') {
		my $url = shift;
		$url =~ s/\?[^\/]+$//;
		my $r1 = shift(@_);
		$r1 = '00' unless(defined $r1);
		my $r2 = shift(@_);
		$r2 = '24' unless(defined $r2);
		my @parts = split(/\?/,$url);
		my @urls;
		if($parts[1]) {
			for my $guess(($r1>$r2 ? reverse($r2 .. $r1) : $r1 .. $2)) {
				push @urls,$parts[0] . $guess . $parts[1];
			}
		}
		else {
			push @urls,$url;
		}
		my $ok;
		foreach my $url(@urls) {
			print STDERR "\tTesting $url ...\n";
			open FI,'-|','curl','--silent','-I',$url;
			while(<FI>) {
				if(m/HTTP.*200\s*OK/) {
					$ok = $url;
					last;
				}
			}
			close FI;
			last if($ok);
		}
		if($ok) {
			print STDERR "\tOK:$ok\n";
			print STDERR "\tWriting to urls.lst ...\n";
			my $base = $ok;
			$base =~ s/\.[^\/]+$//;
			open FO,'>>','urls.lst';
			print FO $base . ".jpg\n";
			print STDERR $base . ".jpg\n";
			print FO $base . ".flv\n";
			print STDERR $base . ".flv\n";
			close FO;
			return 0;
		}
		else {
			print STDERR "No valid url found!\n";
		}
	}
}


return 1 if caller;
my $PROGRAM = MyPlace::Weipai->new();
exit $PROGRAM->execute(@ARGV);

1;
