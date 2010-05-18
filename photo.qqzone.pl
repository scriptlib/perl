#!/usr/bin/perl -w
use strict;
use utf8;
use Encode;


die("Usage:$0 ID [name]\n") unless(@ARGV);

my $gb = find_encoding("gb2312");

sub get_list {
    my $url = shift;
    open FI,"-|", "httpget.pl","$url" or return undef;
    my $code="";
    while(<FI>) {
        $_ =~ s/^\s*_Callback\s*\(//;
        $_ =~ s/^\s*\);/;/;
        $_ =~ s/\s+:\s+/=>/g;
        $code = $code . $_; 
    }
    close FI;
    $code = $gb->decode($code);
    return eval($code);
    
}

sub get_album_list {
    my $uin = shift;
    open FI,"-|", "httpget.pl","http://alist.photo.qq.com/fcgi-bin/fcg_list_album?uin=$uin&outstyle=2" or return undef;
#   open FI,"-|", "httpget.pl","http://xalist.photo.qq.com/fcgi-bin/fcg_list_album?uin=$uin&outstyle=2" or return undef;
    my $code="";
    while(<FI>) {
        $_ =~ s/^\s*_Callback\s*\(//;
        $_ =~ s/^\s*\);/;/;
        $_ =~ s/\s+:\s+/=>/g;
        $code = $code . $_; 
    }
    close FI;
    $code = $gb->decode($code);
    return eval($code);
    
}
sub get_photo_list {
    my $uin = shift;
    my $id = shift;
    open FI,"-|","httpget.pl","http://plist.photo.qq.com/fcgi-bin/fcg_list_photo?uin=$uin&albumid=$id&outstyle=2" or return undef;
    #open FI,"-|","httpget.pl","http://xaplist.photo.qq.com/fcgi-bin/fcg_list_photo?uin=$uin&albumid=$id&outstyle=2" or return undef;
    my $code="";
    while(<FI>) {
        $_ =~ s/^\s*_Callback\s*\(//;
        $_ =~ s/^\s*\);\s*$/;/;
        $_ =~ s/\s+:\s+/=>/g;
        $code = $code . $_; 
    }
    close FI;
    $code = $gb->decode($code);
    return eval($code);
}    
#Photo List:

my $uin = shift;
my $name = shift;
$name = $uin unless($name);

my %url_map = (
    "http://alist.photo.qq.com/fcgi-bin/fcg_list_album?uin=###UIN###&outstyle=2" =>
    "http://plist.photo.qq.com/fcgi-bin/fcg_list_photo?uin=###UIN###&albumid=###ALBUMID###&outstyle=2",
    "http://xalist.photo.qq.com/fcgi-bin/fcg_list_album?uin=###UIN###&outstyle=2" =>
    "http://xaplist.photo.qq.com/fcgi-bin/fcg_list_photo?uin=###UIN###&albumid=###ALBUMID###&outstyle=2",
);

my $good_url;
foreach my $album_exp (keys %url_map) {
    my $album_url = $album_exp;
    $album_url =~ s/###UIN###/$uin/;
    my $list_ref = get_list($album_url);
    next unless($list_ref and ref $list_ref);
    my $albums = $list_ref->{"album"};
    next unless($albums and ref $albums);
    print STDERR "For $name,  Get " . scalar(@{$albums}) . " albums.\n";
    $good_url=1;
    mkdir $name unless(-d $name);
    chdir $name or die("$!\n");
    foreach my $album (@{$albums}) {
        my $album_name = $album->{"name"};
        $album_name =~ s/^[\s　]+//;
        $album_name =~ s/[\s　]+$//;
        $album_name = "_noname" unless($album_name);
        mkdir $album_name unless(-d $album_name);
        chdir $album_name or die("$!\n");
        print STDERR "Downloading [$album_name] ...\n";
        my $photo_url = $url_map{$album_exp};
        $photo_url =~ s/###UIN###/$uin/;
        $photo_url =~ s/###ALBUMID###/$album->{id}/;
        my $photo_list_ref = get_list($photo_url);
        next unless($photo_list_ref and ref $photo_list_ref);
        my $photos = $photo_list_ref->{"pic"};
        next unless($photos and ref $photos);
        print STDERR "Get " . scalar(@{$photos}) . " photos.\n";
        foreach my $photo (@{$photos}) {
           my $url = $photo->{"origin_url"};
           my $filename = $photo->{"name"};
           $filename =~ s/^[　\s]+//;
           $filename =~ s/[\s　]+$//;
           system("download","-u",$url,"-s",$filename . "_" . $photo->{"lloc2"} . ".jpg");
        }
        chdir "..";
    }
    chdir "..";
    last if($good_url);
}

print "Can't get any photos\n" unless($good_url);

