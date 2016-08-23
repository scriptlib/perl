#!/usr/bin/perl -w
package MyPlace::Downloader::HLS;
use strict;
use warnings;

use base 'MyPlace::Program';
use MyPlace::Program::Download;
use MyPlace::URLRule;
use URI;


my $UR;
my $DOWNLOADER;

sub new {
	my $class = shift;
	return bless {@_},$class;
}
sub _download_m3u8 {
	my ($url,$basename,$ext) = @_;
	$DOWNLOADER = $DOWNLOADER || new MyPlace::Program::Download;
	
	my $f_m3u = $basename . ".m3u8";
	
	if(!-f $f_m3u) {
		$DOWNLOADER->execute("--url",$url,"--saveas",$f_m3u,"--maxtry",4);
		return undef,$f_m3u unless(-f $f_m3u);
	}
	if(!open FI,"<:utf8",$f_m3u) {
		print STDERR "Error opening file $f_m3u: $!\n";
		return undef,$f_m3u;
	}
	my @urls;
	while(<FI>) {
		chomp;
		if(!m/^#/) {
			push @urls,URI->new_abs($_,$url)->as_string;
		}
	}
	close FI;
	unlink $f_m3u;
	my $idx = 0;
	my $count = @urls;
	my @data;
	my @files;
	foreach(@urls) {
		$idx++;
		my $output = $basename . '_' .  $idx . $ext;
		print STDERR "  [$idx/$count] ";
		$DOWNLOADER->execute("--url",$_,"--saveas",$output,"--maxtry",4);
		if(-f $output) {
			open FI,'<:raw',$output;
			push @data,<FI>;
			close FI;
			push @files,$output;
		}
		else {
			print STDERR "Download playlist falied\n";
			return undef,$output;
		}
	}
	if(@data) {
		open FO,">:raw",$basename . $ext or return;
		print FO @data;
		close FO;
		print STDERR "Playlist saved to : $basename$ext\n";
		unlink @files;
	}
	return $url,$basename . $ext;
}

sub download {
	my $self = shift;
	my $OPTS = $self->{OPTS};
	my $line = shift;
	my $url = shift;
	my $output = shift;
	if(!$url) {
		$url = $line;
		if($url =~ m/^([^\t]+)\t(.*)$/) {
			$url = $1;
			$output = $2;
		}
	}
	$url =~ s/^hls/http/;
	if(!$output) {
		$output = $url;
		$output =~ s/.*\///;
		$output =~ s/\.[^\.]+$//;
		$output = $output . ".ts";
	}
	my ($basename,$ext) = ($output,$output);
	$basename =~ s/\.[^\.]+$//;
	$ext =~ s/^.*(\.[^\.]+)$/$1/;
	
	
	if($output and -f $output) {
		print STDERR "> Ignored <$url>\n\tFile exists: $output\n";
		return $self->EXIT_CODE('OK');
	}

	my($ok,$dst) = _download_m3u8($url,$basename,$ext);
	if(!$ok) {
		#	print STDERR "No video found on page: $url\n";
		return $self->EXIT_CODE('ERROR');
	}
	return $self->EXIT_CODE('OK');
}

sub MAIN {
	my $self = shift;
	my $OPTS = shift;
	$self->{OPTS} = $OPTS;
	my @lines = @_;
	if(!@lines) {
		while(<STDIN>) {
			chomp;
			push @lines,$_;
		}
	}
	if((scalar(@lines) == 1) and $self->{OPTS}->{output}) {
		$lines[0] .= "\t" . $self->{OPTS}->{output};
	}
	my $exit;
	foreach my $url (@lines) {
		$exit = $self->download($url);
	}
	return $exit;
}

return 1 if caller;
my $PROGRAM = new(__PACKAGE__);
exit $PROGRAM->execute(@ARGV);

1;
