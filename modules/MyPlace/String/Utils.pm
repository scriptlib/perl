#!/usr/bin/perl -w
use strict;
use warnings;
package MyPlace::String::Utils;
BEGIN {
    require Exporter;
    our ($VERSION,@ISA,@EXPORT,@EXPORT_OK,%EXPORT_TAGS);
    $VERSION        = 1.00;
    @ISA            = qw(Exporter);
    @EXPORT         = qw();
    @EXPORT_OK      = qw(dequote no_empty strtime strtime2 utf8_repack from_xdigit);
}
use utf8;
my $DEBUG=0;
my @QUOTES = (
	[qw/【 】/],
	[qw/\[ \]/],
	[qw/\( \)/],
	[qw/《 》/],
	[qw/〔 〕/],
	[qw/〈 〉/],
	[qw/「 」/],
	[qw/『 』/],
	[qw/〖 〗/],
	[qw/｛ ｝/],
	[qw/［ ］/],
	[qw/（ ）/],
	[qw/‘ ’/],
	[qw/“ ”/],
);

sub setflag {
	foreach(@_) {
		if($_ eq 'debug') {
			$DEBUG = 1;
		}
	}
}

sub dequote_test {
	print STDERR dequote("【被催眠的冰球选手】作者：不明.txt\n");
}

sub dequote {
	local $_ = shift;
	return unless($_);
	print STDERR "TARGET: $_\n" if($DEBUG);
	foreach my $q(@QUOTES) {
		print STDERR "QUOTE: ",join(" ",@{$q}),"\n" if($DEBUG);
		my $exp = '^(.*?)' . $q->[0] . '([^'. $q->[1] . ']*)' . $q->[1] . '(.*)$';
		print STDERR "Exp: $exp\n" if($DEBUG);
		while(m/$exp/g) {
			print STDERR "\tMatch!\n" if($DEBUG);
			my $r = ($1 ? $1 . "_" : "") . $2 . ($3 ? "_$3" : "");
			s/$exp/$r/;
		}
	}
	return $_;
}

sub no_empty {
	my $text = shift;
	my $prefix = shift || "";
	my $suffix = shift || "";
	my $default = shift || "";
	if(!$text) {
		return $default;
	}
	else {
		return "$prefix$text$suffix";
	}
}

sub format_time {
	my $r = shift;
	my @r = (@$r);
	my $style = shift;
	my $sep1 = shift(@_); 
	my $sep2 = shift(@_);
	my $sep3 = shift(@_);
	$sep1 = "/" unless(defined $sep1); #seperator for date (year/month/day)
	$sep2 = ":" unless(defined $sep2); #seperator for time (hour::minute::second)
	$sep3 = " " unless(defined $sep3); #seperator seperated date and time
	my $year   = $r[5] < 1000 ? $r[5] + 1900 : $r[5];
	my $month  = $r[4]  > 8  ? ($r[4] + 1) : '0' . ($r[4]+1);
	my $day    = $r[3] > 9 ? $r[3] : '0' . $r[3];
	my $hour   = $r[2] > 9 ? $r[2] : '0' . $r[2];
	my $minute = $r[1] > 9 ? $r[1] : '0' . $r[1];
	my $second = $r[0] > 9 ? $r[0] : '0' . $r[0];
	my $clock = "$hour$sep2$minute$sep2$second";
	if((!$style) or ($style == 4)) {
		return "$year$sep1$month$sep1$day$sep3$clock";
	}
	elsif($style == 3) {
		return "$month$sep1$day$sep3$clock";
	}
	elsif($style == 2) {
		return "$day $clock";
	}
	elsif($style == 1) {
		return $clock;
	}
	elsif($style == -1) {
		return "$year$sep1$month$sep1$day";
	}
	elsif($style == -2) {
		return "$month$sep1$day";
	}
	elsif($style == 5) {
		return "$year$month$day";
	}
	elsif($style == -5) {
		return "$year$month$day$hour$minute$second";
	}
	else {
		return "$year$sep1$month$sep1$day$sep3$clock";
	}
}

sub strtime {
	my $time =  shift(@_) || time();
	my @r = localtime($time);
	return format_time([@r],@_);
}

sub strtime2 {
	my %MONTHMAP = (
	"Jan"=>0,
	"Feb"=>1,
	"Mar"=>2,
	"Apr"=>3,
	"May"=>4,
	"Jun"=>5,
	"Jul"=>6,
	"Aug"=>7,
	"Sep"=>8,
	"Oct"=>9,
	"Nov"=>10,
	"Dec"=>11,
	);
	my $str = shift;
	my @r;
	my @c = localtime();
	my $r = $str;
	if(!$r) {
		return undef;
	}
	elsif($r =~ m/(\w\w\w) (\d+) (\d+):(\d+):(\d+) \+(\d+) (\d+)$/) {
		$r[5] = $7;
		my $m = $MONTHMAP{ucfirst($1)};
		$r[4] = $m ? $m : $c[1];
		$r[3] = +$2 - 0;
		$r[2] = +$3 - 0;
		$r[1] = +$4 - 0;
		$r[0] = +$5 - 0;
	}
	elsif($r =~ m/(\d\d\d\d)[_-](\d+)[_-](\d+)$/) {
		$r[5] = $1;
		$r[4] = +$2 - 1;
		$r[3] = +$3 - 0;
		$r[2] = 0;
		$r[1] = 0;
		$r[0] = 0;
	}
	elsif($r =~ m/(\d+)[_-](\d+)$/) {
		$r[5] = $c[5];
		$r[4] = +$1 - 1;
		$r[3] = +$2 - 0;
		$r[2] = 0;
		$r[1] = 0;
		$r[0] = 0;
	}
	else {
		return $str;
	}
	my $style = shift;
	return format_time(\@r,(defined $style ? $style : -5),@_);
}

sub utf8_repack {
	foreach(@_) {
		s/\\u([0-9a-fA-F]{4})/pack("U",,hex($1))/eg;
	}
	return @_;
}

sub from_xdigit {
	my %digit = (
        "&#xe60d;"=>0,
        "&#xe603;"=>0,
        "&#xe616;"=>0,
        "&#xe60e;"=>1,
        "&#xe618;"=>1,
        "&#xe602;"=>1,
        "&#xe605;"=>2,
        "&#xe610;"=>2,
        "&#xe617;"=>2,
        "&#xe611;"=>3,
        "&#xe604;"=>3,
        "&#xe61a;"=>3,
        "&#xe606;"=>4,
        "&#xe619;"=>4,
        "&#xe60c;"=>4,
        "&#xe60f;"=>5,
        "&#xe607;"=>5,
        "&#xe61b;"=>5,
        "&#xe61f;"=>6,
        "&#xe612;"=>6,
        "&#xe608;"=>6,
        "&#xe61c;"=>7,
        "&#xe60a;"=>7,
        "&#xe613;"=>7,
        "&#xe60b;"=>8,
        "&#xe61d;"=>8,
        "&#xe614;"=>8,
        "&#xe615;"=>9,
        "&#xe61e;"=>9,
        "&#xe609;"=>9,
);
	foreach(@_) {
		foreach my $k(keys %digit){
			s/$k/$digit{$k}/g;
		}
	}
	if(wantarray) {
		return @_;
	}
	else {
		return shift(@_);
	}

}

1;
