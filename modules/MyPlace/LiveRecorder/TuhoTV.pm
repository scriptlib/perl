#!/usr/bin/perl -w
package MyPlace::LiveRecorder::TuhoTV;
use strict;
use warnings;
BEGIN {
    require Exporter;
    our ($VERSION,@ISA,@EXPORT,@EXPORT_OK,%EXPORT_TAGS);
    $VERSION        = 1.00;
    @ISA            = qw(Exporter);
    @EXPORT_OK      = qw(&get_userinfo);
}
use parent 'MyPlace::LiveRecorder';
use JSON qw/decode_json/;
use Encode qw/from_to decode encode find_encoding/;
use MyPlace::URLRule::Utils qw/get_url extract_title/;
use utf8;

our @TUHO_CURL_OPTS = (
	"--connect-timeout"=>"60",
	"-b"=>"PHPSESSID=5s6tism4m3lh1tcftpm3hldrf2; uid=4392330",
);

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
	my $raw = get_url(@_);
	return safe_decode_json($raw);
}

sub get_userinfo {
	my $uid = shift;
	my $url = 'http://app.guojiang.tv/user/getUserInfo/platform/iphone/version/2.8.0/packageId/7/bundleId/tv.tuhao.kuaishou/uid/' . $uid;
	my $json = get_json($url,'-v',@TUHO_CURL_OPTS);
	if(!ref $json) {
		print STDERR "Error decode url content\n";
		return {}
	}
	if($json->{errno} != 0) {
		print STDERR "Request failed: $json->{msg} [errno:$json->{errno}]\n";
		return %$json;
	}
	if(!ref $json->{data}) {
		print STDERR "Request failed: no data return\n";
		return %$json;
	}
	my %info;
	$json = $json->{data};
	foreach my $k(qw/level fansNum birthday sex rid flowerNumber attentionNum/) {
		$info{$k} = $json->{$k};
	}
	my $utf8 = find_encoding("utf-8");
	foreach my $k(qw/nickname signature/) {
		$info{$k} = $utf8->encode($json->{$k});
	}
	$info{uname} = extract_title($info{nickname});
	$info{uid} = $uid;
	$info{playlist} = $json->{videoPlayUrl};
	$info{cover} = $json->{headPic};
	$info{data} = [$json->{bgImg}];
	$info{online} = 1 if($json->{isPlaying});
	$info{uname} = $info{uid} unless($info{uname});
	$info{host} = 'tuho.tv';
	$info{profile} = $info{uid};
	$info{title} = $info{uname};
	print STDERR $info{uname},"\t",$info{signature},"\n";
	my @text;
	foreach(keys %info) {
		push @text,"$_: $info{$_}\n";
	}
	$info{text} = \@text;
	return %info;
}

sub check {
	my $self = shift;
	my $id = shift;
	my $name = shift;
	my %info = get_userinfo($id);
	$self->{"info_$id"} = \%info;
	if($info{online}){
		return 1;
	}
	else {
		return undef;
	}
}

sub def_live {
	my $self = shift;
	my $id = shift;
	if(not $self->{"info_$id"}) {
		my $a = $self->check($id);
		if(!$a) {
			return undef;
		}
	}
	return undef if(not $self->{"info_$id"});
	my $rtmp = $self->{"info_$id"}->{playlist};
	return undef unless($rtmp);
	#delete $self->{"info_$id"};
	return {SYSTEM=>1,CURL=>['record_rtmp',$rtmp,'--dump'],EXT=>".mp4"};
}

sub new {
	my $class = shift;
	my $self = $class->SUPER::new('TuhoTV');
	if(@_) {
		$self->set(@_);
	}
	return $self;
}

sub MAIN {
	my $self = shift;
	my $OPTS = shift;
	#use MyPlace::Debug::Dump;die(debug_dump($OPTS),"\n");
	return $self->start($OPTS,@_);
}

return 1 if caller;
my $PROGRAM = new MyPlace::LiveRecorder::TuhoTV;
exit $PROGRAM->execute(@ARGV);
 

