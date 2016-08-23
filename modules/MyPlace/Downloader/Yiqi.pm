#!/usr/bin/perl -w
package MyPlace::Downloader::Yiqi;
use strict;
use warnings;
BEGIN {
    require Exporter;
    our ($VERSION,@ISA,@EXPORT,@EXPORT_OK,%EXPORT_TAGS);
    $VERSION        = 1.00;
    @ISA            = qw(Exporter);
    @EXPORT         = qw(download_xiaoying);
    @EXPORT_OK      = qw();
}

use base 'MyPlace::Program';


sub new {
	my $class = shift;
	return bless {@_},$class;
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
	if($output and -f $output) {
		print STDERR "> Ignored <$url>\n\tFile exists: $output\n";
		return $self->EXIT_CODE('OK');
	}

	my $id;
	my $name;
	my $time;
	
	if(!$output) {
		if($url =~ m/(\d+)\.[^\.]+$/) {
			$id = $1;
		}
		else {
			print STDERR "No id found for url: $url ($output)\n";
			return $self->EXIT_CODE('ERROR');
		}
	}
	elsif($output =~ m/^(\d+)_(\d+)_(.+)\.[^\.]+$/) {
		$id = $2;
		$name = $3;
		$time = $1;
	}
	elsif($output =~ m/^(\d+)_(.+)\.[^\.]+$/) {
		$id = $1;
		$name = $2;
	}
	elsif($url =~ m/(\d+)\.[^\.]+$/) {
		$id = $1;
	}
	else {
		print STDERR "No id found for url: $url ($output)\n";
		return $self->EXIT_CODE('ERROR');
	}
	system('record_yiqi1717',$id,$name || "",$time || "");
	return $self->EXIT_CODE('UNKNOWN');
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

sub download_xiaoying {
	my $PROGRAM = new(__PACKAGE__);
	my $exit = 0;
	foreach(@_) {
		$exit = $PROGRAM->download($_) 
	}
	return $exit == 0;
}

return 1 if caller;
my $PROGRAM = new(__PACKAGE__);
exit $PROGRAM->execute(@ARGV);

1;
 

