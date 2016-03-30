#!/usr/bin/perl -w
package MyPlace::Downloader::Weishi;
use strict;
use warnings;
BEGIN {
    require Exporter;
    our ($VERSION,@ISA,@EXPORT,@EXPORT_OK,%EXPORT_TAGS);
    $VERSION        = 1.00;
    @ISA            = qw(Exporter);
    @EXPORT         = qw(download_weishi);
    @EXPORT_OK      = qw();
}

use base 'MyPlace::Program';
use MyPlace::Program::Download;
use MyPlace::URLRule;


my $UR;

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
	
	$UR ||= new MyPlace::URLRule;
	my $result = $UR->post_process($UR->process($url,0));
	if(!$result) {
		return $self->EXIT_CODE('ERROR');
	}
	my $data = $result->{download};
	if(!$data) {
		print STDERR "No downloads found on page: $url\n";
		return $self->EXIT_CODE('ERROR');
	}
	if(!$output) {
		$output = $result->{name} . ".mp4" if($result->{name});
	}
	my $lastexit = 0;
	my $dl = new MyPlace::Program::Download;
	foreach my $url(@$data) {
		if(!$output) {
			$lastexit = $dl->execute($url);
		}
		elsif(-f $output) {
			print STDERR "> Ignored <$url>\n\tFile exists: $output\n";
			$lastexit = $self->EXIT_CODE('OK');
		}
		else {
			$lastexit = $dl->execute($url,'-o',$output);

		}
	}
	return $lastexit;
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

sub download_weishi {
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
 

