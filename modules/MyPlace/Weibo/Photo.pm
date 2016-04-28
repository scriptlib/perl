#!/usr/bin/perl -w
use strict;
use warnings;
package MyPlace::Weibo::Photo;
BEGIN {
    require Exporter;
    our ($VERSION,@ISA,@EXPORT,@EXPORT_OK,%EXPORT_TAGS);
    $VERSION        = 1.00;
    @ISA            = qw(Exporter);
    @EXPORT         = qw(get_albums get_photos);
    @EXPORT_OK      = qw(get_albums get_photos get_url);
}

use MyPlace::Weibo;
use JSON qw/decode_json/;
use base 'MyPlace::Program';

sub get_url {
	goto &MyPlace::Weibo::get_url;
}

sub get_albums {
	my ($uid,$page,$count) = @_;
	return {error=>"Invalid uid: $uid"} unless($uid and $uid =~ m/^\d+$/);
	$page = 1 unless($page and $page>0);
	$count = 5 unless($count and $count>0);
	my $API_URL='http://photo.weibo.com/albums/get_all?' .
		join("&","uid=$uid","page=$page","count=$count","__rnd=" . time . '820');
	use MyPlace::Debug::Dump;
	my $html = get_url($API_URL,'-v','--referer','http://photo.weibo.com/albums/' . $uid);
#	print STDERR $html,"\n";
	my $j = decode_json($html);
	if(!$j->{result}) {
		print STDERR "Error $j->{code}: " . $j->{msg} . "\n";
		return undef,$j->{msg};
	}
	foreach(@{$j->{data}->{album_list}}) {
		$_->{id} = $_->{album_id};
		$_->{count} = $_->{count}->{photos};
		$_->{caption} = $_->{caption} || $_->{description};
	}
	return $j->{data}->{total},$j->{data}->{album_list} ? @{$j->{data}->{album_list}} : ();
}
sub get_photos {
	my ($uid,$page,$count) = @_;
	return {error=>"Invalid uid: $uid"} unless($uid and $uid =~ m/^\d+$/);
	$page = 1 unless($page and $page>0);
	$count = 5 unless($count and $count>0);
	my $API_URL='http://photo.weibo.com/photos/get_all?' .
		join("&","album_id=$uid","page=$page","count=$count","type=1","__rnd=" . time . '820');
	my $html = get_url($API_URL,'-v','--referer','http://photo.weibo.com/albums/' . $uid);
#	print STDERR $html,"\n";
	my $j = decode_json($html);
	if(!$j->{result}) {
		print STDERR "Error $j->{code}: " . $j->{msg} . "\n";
		return undef,$j->{msg};
	}
	foreach(@{$j->{data}->{photo_list}}) {
		$_->{id} = $_->{photo_id};
		$_->{caption} = $_->{caption} || $_->{description} || '';
		$_->{src} = $_->{pic_host} . "/large/" . $_->{pic_name};
	}
	return $j->{data}->{total},$j->{data}->{photo_list} ? @{$j->{data}->{photo_list}} : ();
}


sub OPTIONS {qw/
	help|h|? 
	manual|man
	albums
	photos
	id|u|i=i
	page|p=i
	count|c=i
/;}
#binmode STDERR,'utf8';
#binmode STDOUT,'utf8';
sub MAIN {
	my $self = shift;
	my $OPTS = shift;
	$self->{OPTS} = $OPTS;
	my $target;
	if($OPTS->{albums}) {
		$target = 'albums';
	}
	elsif($OPTS->{photos}) {
		$target = 'photos';
	}
	elsif($OPTS->{target}) {
		$target = $self->{target};
	}
	elsif(@_) {
		$target = lc(shift(@_));
		$target =~ s/^get-*//;
	}
	else {
		print STDERR "Invalid usage, no target/action specified!\n";
		return 1;
	}
	my $id = $OPTS->{id} || shift(@_) || "";
	if(!($id and $id =~ m/^\d+$/)) {
		print STDERR "Invalid or none ID specified:$id\n";
		return 2;
	}
	my $page = $OPTS->{page} || shift(@_) || 1;;
	if(!($page and $page=~ m/^\d+$/)) {
		print STDERR "Invalid PAGE specified:$page\n";
		return 3;
	}
	my $count = $OPTS->{count} || shift(@_) || 10;;
	if(!($count and $count=~ m/^\d+$/)) {
		print STDERR "Invalid COUNT specified:$count\n";
		return 4;
	}
	if($target eq 'albums') {
		my($st,@ab) = get_albums($id,$page,$count);
		if(!$st) {
			print STDERR join(" ",@ab),"\n";
			return 5;
		}
		print "Total $st albums exsits, $count albums in page $page:\n";
		foreach(@ab) {
			print "  #$_->{album_id}: <$_->{count}> $_->{caption}\n";
		}
		return 0;
	}
	elsif($target eq 'photos' or $target eq 'album' or $target eq 'photo') {
		my($st,@ab) = get_photos($id,$page,$count);
		if(!$st) {
			print STDERR join(" ",@ab),"\n";
			return 6;
		}
		print "Total $st photos exsits, $count photos in page $page:\n";
		foreach(@ab) {
			print "  #$_->{id}: $_->{src} $_->{caption}\n";
		}
		return 0;
	}
	else {
		print STDERR "Error: invalid target/action specified: $target\n";
		return 7;
	}
	
}

return 1 if caller;
my $PROGRAM = new MyPlace::Weibo::Photo;
exit $PROGRAM->execute(@ARGV);
