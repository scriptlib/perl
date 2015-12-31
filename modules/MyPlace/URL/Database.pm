#!/usr/bin/perl -w
use strict;
use warnings;
BEGIN {
    require Exporter;
    our ($VERSION,@ISA,@EXPORT,@EXPORT_OK,%EXPORT_TAGS);
    $VERSION        = 1.00;
    @ISA            = qw(Exporter);
    @EXPORT         = qw(url_database_read url_database_write url_database_check);
    @EXPORT_OK      = qw();
}

our @DOMAINS = (
	['v.weipai.cn','oldvideo.qiniudn.com'],
	['aliv3.weipai.cn', 'aliv.weipai.cn'],
);

sub DUP_URL {
	my $url = shift;
	my @r;
	my $lurl = $url;
	my $prefix;
	my $domain;
	my $suffix;
	if($lurl =~ m/^([a-z]+:\/\/)([^\/]+)(.*)$/) {
		$prefix = $1;
		$domain = lc($2);
		$suffix = $3;
	}
	else {
		return ($url);
	}
	foreach (@DOMAINS) {
		my $match = 0;
		foreach my $d(@$_) {
			if(lc($d) eq $domain) {
				$match = 1;
				last;
			}
		}
		if($match) {
			foreach my $d(@$_) {
				push @r, $prefix . $d . $suffix;
			}
			last;
		}
	}
	if(@r) {
		#	print STDERR "[DUPURL] $url =>\n";
		#print STDERR "\t" . join("\n\t",@r) . "\n";
		return @r;
	}	
	return ($url);
}

sub url_database_read {
	my $f_urls = shift;
	my $map_domains = shift;
	my $count =  shift;
	my @records;
	if(-f $f_urls) {
		print STDERR "[URL Database] Reading $f_urls\n";
		if(open FI,'<',$f_urls) {
			foreach(<FI>) {
				chomp;
				if($map_domains) {
					push @records,DUP_URL($_);
				}
				else {
					push @records,$_;
				}
			}
			close FI;
		}
		else {
			print STDERR "\tError reading $f_urls:$!\n";
			return undef;
		}
	}
	return (1,$count,\@records);
}

sub url_database_write {
	my $f_urls = shift;
	my $data = shift;
	my $mode = shift;
	$mode = uc($mode) if($mode);
	my $status;
	my $OPMODE = '>>';
	my @TOWRITE;
	my @EXIT;
	if(!$mode) {
		$OPMODE = '>>';
		my @records = url_database_read($f_urls);
		my %filter = map {$_,1},@records;
		foreach (@$data) {
			if(!$filter{$_}) {
				push @TOWRITE,$_;
			}
		}
		@EXIT = (1,scalar(@TOWRITE),\@TOWRITE);
	}
	elsif($mode eq 'RECORD') {
		my $records = shift;
		my %filter = map {$_,1},@$records;
		foreach (@$data) {
			if(m/weishi\.com|weishi_pic/) {
				$status = undef;
				last;
			}
			elsif(!$filter{$_}) {
				push @TOWRITE,$_;
			}
		}
		@EXIT = ($status,scalar(@TOWRITE),\@TOWRITE);
	}
	elsif($mode eq 'APPEND') {
		$OPMODE = '>>';
		@TOWRITE = @$data;
		@EXIT = (1,scalar(@TOWRITE),\@TOWRITE);
	}
	elsif($mode eq 'REWRITE') {
		$OPMODE = '>';
		@TOWRITE = @$data;
		@EXIT = (1,scalar(@TOWRITE),\@TOWRITE);
	}

	if(open FO,$OPMODE,$f_urls) {
		print FO join("\n",@TOWRITE),"\n";
		close FO;
		return @EXIT;
	}
	else {
		print STDERR "\tError opening file $f_urls: $!\n";
		return undef;
	}
}

	sub url_database_check {
		my $f_urls = shift;
		my $data = shift;
		my $count = 0;
		my $OUTDATE = 1;
		my @records = url_database_read($f_url,1);
		my($status,$count,$urls) = url_database_write($f_url,$data,'RECORD',\@records);
		if(!$status) {
			$OUTDATE = 1;
		}
		if(!$count) {
			return undef;
		}
		return 1,$count,$urls;
	}

