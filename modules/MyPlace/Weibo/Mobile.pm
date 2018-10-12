#!/usr/bin/perl -w
#
#===============================================================================
#
#         FILE: Mobile.pm
#
#  DESCRIPTION: 
#
#        FILES: ---
#         BUGS: ---
#        NOTES: ---
#       AUTHOR: Eotect Nahn (eotect), eotect@myplace.hel
# ORGANIZATION: MyPlace HEL. ORG.
#      VERSION: 1.0
#      CREATED: 2018/09/17  2:00:12
#     REVISION: ---
#===============================================================================
package MyPlace::Weibo::Mobile;
use strict;
use warnings;
BEGIN {
    require Exporter;
    our ($VERSION,@ISA,@EXPORT,@EXPORT_OK,%EXPORT_TAGS);
    $VERSION        = 1.00;
    @ISA            = qw(Exporter);
    @EXPORT         = qw();
    @EXPORT_OK      = qw();
}
use base 'MyPlace::Program';
use JSON qw/decode_json encode_json from_json to_json/;
use MyPlace::Curl;
my $private_curl;
my $cookie = $ENV{HOME} . "/.curl_cookies.dat";
sub get_curl {
	if(not $private_curl) {
		$private_curl = MyPlace::Curl->new(
			'user-agent'=>'Mozilla/5.0 (Android 9.0; Mobile; rv:61.0) Gecko/61.0 Firefox/61.0',
			"location"=>'',
			"silent"=>'',
			"show-error"=>'',
			"cookie"=>$cookie,
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


sub get_id {
	my $self = shift;
	my $url = shift;
	my $id;
	if($url =~ m/^(\d+)$/) {
		$id = $1;
	}
	elsif($url =~ m/\/u\/(\d+)$/) {
		$id = $1;
	}
	elsif($url =~ m/[\?&]uid=(\d+)/) {
		$id = $1;
	}
	else {
		my $data = get_url($url);
		if($data =~ m/"type":"uid","value":"(\d+)"/) {
			$id = $1;
		}
		elsif($data =~ m/\$CONFIG\['oid'\]='(\d+)'; /) {
			$id = $1;
		}
	}
	return 0 unless($id);
	return $id;
}

my %API = (
	profile=>'https://m.weibo.cn/api/container/getIndex?type=uid&value=###UID###&containerid=100505###UID###',
	posts=>'https://m.weibo.cn/api/container/getIndex?uid=###UID###&luicode=10000011&lfid=107603###UID###&type=uid&value=###UID###&containerid=107603###UID###',
);

sub get_data {
	my $url = shift;
	my $data = get_url($url);
	if($data =~ m/"ok":1/) {
		$data = decode_json($data);
		return $data->{data};
	}
	return {error=>1,data=>$data};
}

sub get_profile {
	my ($self,$url) = @_;
	my $id = $self->get_id($url);
	$url = $API{profile};
	$url =~ s/###UID###/$id/g;
	my $json = get_data($url);
	my $data = $json;
	if($json->{userInfo}) {
		$data = {%{$json->{userInfo}}};
		foreach(keys %$data) {
			delete $data->{$_} unless(m/(?:id|screen_name|statuses_count|avatar_hd)/)
		}
	}
	if(wantarray) {
		return $data,$json;
	}
	else {
		return $data;
	}
}

sub get_posts {
	my ($self,$url,$from) = @_;
	my $id = $self->get_id($url);
	$url = $API{posts};
	$url =~ s/###UID###/$id/g;
	if($from) {
		$url = $url . "&since_id=$from";
	}
	my $json = get_data($url);
	my $data = $json;
	if($json->{cards}) {
		$data = [@{$json->{cards}}];
		foreach(@$data) {
			$_ = {%{$_->{mblog}},scheme=>$_->{scheme}};
			foreach my $k(keys %$_) {
				delete $_->{$k} unless($k =~ m/^(?:scheme|id|text|created_at|bid)$/);
			}
		}
	}
	if(wantarray) {
		return $data,$json;
	}
	else {
		return $data;
	}
}

sub OPTIONS {qw/
	help|h
/};

sub MAIN {
	my $self = shift;
	my $OPTS = shift;
	$self->{OPTS} = $OPTS;
	use Data::Dumper;
	print STDERR Data::Dumper->Dump([$OPTS,\@_],['OPTIONS','ARGS']),"\n";

	my $command = shift;
	$command = uc($command);
	if($command eq 'GET_PROFILE') {
		my $data = $self->get_profile(@_);
		foreach(keys %$data) {
			print "$_ : $data->{$_}\n";
		}
		#print Data::Dumper->Dump([$data],[$command]),"\n";
	}
	if($command eq 'GET_POSTS') {
		my $data = $self->get_posts(@_);
		foreach my $p(@$data) {
			foreach(keys %$p) {
				print "$_ : $p->{$_}\n";
			}
		}
		#print Data::Dumper->Dump([$data],[$command]),"\n";
	}
	return 0;
}
return 1 if caller;
my $PROGRAM = new MyPlace::Weibo::Mobile;
exit $PROGRAM->execute(@ARGV);
1;
