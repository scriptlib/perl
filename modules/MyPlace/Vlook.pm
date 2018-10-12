#!/usr/bin/perl -w
package MyPlace::Vlook;
BEGIN {
    require Exporter;
    our ($VERSION,@ISA,@EXPORT,@EXPORT_OK,%EXPORT_TAGS);
    $VERSION        = 1.00;
    @ISA            = qw(Exporter);
    @EXPORT         = qw();
    @EXPORT_OK      = qw(get_video get_blog_id get_blog_info get_push_videos);
}
use strict;
use warnings;
use base 'MyPlace::Program';
use MyPlace::URLRule::Utils qw/get_url extract_title/;

sub build_push_url {
	my $id = shift;
	return 'http://www.vlook.cn/api/flash_home/pushVideo?s=9&bId=' . $id . '&t=1';
}

sub build_blog_url {
	my $url = shift;
	if($url =~ m/\/qs\/([^\/#\&\?]+)/) {
		$url = 'http://www.vlook.cn/mobile/index/show/qs/' . $1;
	}
	elsif($url !~ m/^\//) {
		$url = 'http://www.vlook.cn/mobile/index/show/qs/' . $url;
	}
	return $url;
}

sub get_push_videos {
	my $id = shift;
	my $url = build_push_url($id);
	my $text = get_url($url,'-v');
    my @videos;
	my @items = split(/<item/,$text);
	foreach my $html (@items) {
		my %info;
		while($html =~ m/<([^>]+)>([^<]+)<\/\1>/g) {
			$info{$1} = $2;
		}
		next unless($info{play});
		$info{play} =~ s/&amp;/&/g;
		if($info{play} =~ m/bid=(\d+)/) {
			$info{bid} = $1;
		}
		if($info{play} =~ /vid=([^&?=#]+)/) {
			$info{vid} = $1;
		}
		push @videos,{bid=>$info{bid},vid=>$info{vid},video=>$info{play},cover=>$info{img},text=>$info{txt},duration=>$info{lastTime}};
	}
	return @videos;
}

sub get_blog_info {
	my $url = build_blog_url(@_);
	my $html = get_url($url,'-v');
    my $title = undef;
	my %info;
	while($html =~ m/<meta[^>]+(?:name|property)\s*=\s*"([^"]+)"[^>]+content\s*=\s*"([^"]+)"/g) {
		$info{$1} = $2;
	}
	if($html =~ m/var blogId = (\d+)/) {
		$info{bid} = $1;
	}
	else {
		return \%info;
	}
	my $video = $info{"og:videosrc"};
		$video =~ s/%3A/:/g;
		$video =~ s/%2F/\//g;
		$video =~ s/%3F/\?/g;
		$video =~ s/%3D/=/g;
		$video =~ s/%26/&/g;
	my $image = $info{"og:image"};
	if($image =~ m/\/([^\/\.]+)\.jpg$/) {
		$info{vid} = $1;
	}
	$title = $info{"og:title"} || $info{vid} || $info{bid};
	$title =~ s/[\/\\]+//g;
	$title = extract_title($title);
	if($info{'weibo:video:create_at'} and $info{'weibo:video:create_at'} =~ m/(\d+)-(\d+)-(\d+)\s*(\d+):(\d+):(\d+)/) {
		$title = $title ? "$1$2$3$4$5$6_$title" : "$1$2$3$4$5$6";
	}
	if($info{'weibo:video:duration'}) {
		my $secs = $info{'weibo:video:duration'};
		my $m = int($secs / 60);
		my $s = $secs % 60;
		my $t = ($m ? "$m分钟" : "") . "$s秒";
		$title = $title ? $title . "_$t" : "$t";
	}
	$title =~ s/[\/\?:\*"']//g;
	return {
		filename=>$title,
		vid=>$info{vid},
		bid=>$info{bid},
		text=>($info{"og:title"} || $info{"og:description"}),
		image=>$info{"og:image"},
		url=>$info{"og:url"},
		type=>$info{"og:type"},
		video=>$info{"og:videosrc"},
		duration=>$info{"weibo:video:duration"},
		ctime=>$info{"weibo:video:create_at"},
	}
}

sub get_video {
	my $id = shift;
	if($id !~ m/^\d+/) {
		$id = get_blog_id($id);
	}
	print STDERR "  get related videos ...\n";
	my @videos = get_push_videos($id);
	foreach(@videos) {
		my $pid = $_->{bid};
		print STDERR "    try related videos from $pid ...\n";
		my @pv = get_push_videos($pid);
		foreach my $ppv(@pv) {
			my $ppid = $ppv->{bid};
			print STDERR "    video id : $ppid ...";
			if($id eq $ppid) {
				print STDERR "\t [OK]\n";
				print STDERR "  OK.\n";
				return $ppv->{video};
			}
			else {
				print STDERR "\t [NO]\n";
			}
		}
	}
	return undef;
}

sub get_blog_id {
	my $url = build_blog_url(@_);
	my $data = get_url($url);
	return "" unless($data);
	if($data =~ m/var blogId = (\d+)/) {
		return $1;
	}
	return "";
}

sub MAIN {
	my $self = shift;
	my $OPTS = shift;
	$self->{OPTS} = $OPTS;
	$self->process(@_);
}
sub USAGE {
	print STDERR "Usage: \n  vlook <command> {argments}\n";
}
sub process {
	my $self = shift;
	my $command = shift;
	return $self->USAGE() unless($command);
	my $cmd = lc($command);
	use Data::Dumper;
	my @v;
	my $exit = eval "\@v = &$cmd(\@_);";
	if(not defined $exit) {
		print STDERR "Error:$@\n";
		return 1;
	}
	print Data::Dumper->Dump([\@v],[$cmd]),"\n";
	return $exit;
}
return 1 if caller;
my $PROGRAM = new MyPlace::Vlook;
exit $PROGRAM->execute(@ARGV);
