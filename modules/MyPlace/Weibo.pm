#!/usr/bin/perl -w
use strict;
use warnings;
package MyPlace::Weibo;
BEGIN {
    require Exporter;
    our ($VERSION,@ISA,@EXPORT,@EXPORT_OK,%EXPORT_TAGS);
    $VERSION        = 1.00;
    @ISA            = qw(Exporter);
    @EXPORT         = qw();
    @EXPORT_OK      = qw(get_url);
}
use MyPlace::Curl;
use MyPlace::Curl;
my $cookie = $ENV{HOME} . "/.curl_cookies.dat";
my $cookiejar = $ENV{HOME} . "/.curl_cookies2.dat";
my $curl = MyPlace::Curl->new(
	"location"=>'',
	"silent"=>'',
	"show-error"=>'',
	"cookie"=>$cookie,
	"cookie-jar"=>$cookiejar,
#	"retry"=>4,
	"max-time"=>120,
);

sub get_url {
	my $url = shift;
	my $verbose = shift(@_) || '-q';
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
	my $status;
	print STDERR "[Retriving URL] $url ..." if($verbose);
	while($retry) {
		($status,$data) = $curl->get($url,@_);
		if($status != 0) {
			print STDERR "[Retry " . (5 - $retry) . "][Retriving URL] $url ..." if($verbose);
		}
		else {
			print STDERR "\t[OK]\n" unless($silent);
			last;
		}
		$retry--;
		sleep 3;
	}
	if(wantarray) {
		return $status,$data;
	}
	else {
		return $data;
	}
}
1;
