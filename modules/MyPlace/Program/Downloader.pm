#!/usr/bin/perl -w
package MyPlace::Program::Downloader;
use strict;
use warnings;
use base 'MyPlace::Program';
use MyPlace::Tasks::Manager;
sub OPTIONS {qw/
	help|h|? 
	manual|man
	input|i=s
	directory|d=s
	title|t=s
	retry
	ignore-failed|g
	simple
	recursive|r
	quiet
	history|hist
	referer=s
	overwrite|o
	force|f
	exclude|X=s
	include|I=s
	count|c=i
	url=s
	touch
	images|img
	videos|vid
	markdone
	no-queue|nq
	no-download
	no-failed|nf
	no-done|nd
	no-ignored|ng
	no-mtm|nm
	config=s
	use=s
	one|1
	worker=s
	nop
	select=s
	print
	mark|m=s
/;}

sub download {
	my $self = shift;
	my @opts = qw/
		quiet
		history
		overwrite
		force
		touch
		markdone
		no-download
	/;
	my @args = ();
	foreach(@opts) {
		if($self->{OPTS}->{$_}) {
			push @args,'--' . $_;
		}
	}
	foreach(qw/max-time connect-timeout/) {
		if($self->{OPTS}->{$_}) {
			push @args,'--' . $_,$self->{OPTS}->{$_};
		}
	}
	my $r = system('downloader',@args,'--',@_);
	$r = $r>>8 if(($r != 0) and $r != 2);
	return $r;
}

sub MAIN {
	my $self = shift;
	my $OPTS = shift;
	$OPTS->{'max-time'} = 1200 unless($OPTS->{'max-time'});
	$OPTS->{'connect-timeout'} = 60 unless($OPTS->{'connect-timeout'});
	$self->{OPTS} = $OPTS;
	if($OPTS->{directory}) {
		system("ls","-ld","--",$OPTS->{directory});
	}
	elsif($OPTS->{url}) {
	}
	elsif(@_) {
		foreach(@_) {
			if(-e $_) {
				system("ls","-ld","--",$_);
			}
		}	
	}
	foreach(qw/select/) {
		next unless(defined $OPTS->{$_});
		if($OPTS->{$_} !~ m/^(?:\d+|\d+\.\.\d+)$/) {
			print STDERR "Option --$_ must be format as <number> or <number .. number>\n";
			return 1;
		}
	}
	if($self->{OPTS}->{url}) {
		return $self->download($self->{OPTS}->{url});
	}
	my @include;
	push @include,$OPTS->{include} if($OPTS->{include});
	push @include,'\.(?:jpg|gif|png|jpeg)' if($OPTS->{images});
	push @include,'\.(?:flv|mov|f4v|avi|mkv|mpg|mpeg|rmvb|asf|wmv|ts|mp4|3pg)' if($OPTS->{'videos'});
	if(@include) {
		$OPTS->{include} = join("|",@include);
	}
	my @exclude;
	push @exclude,$OPTS->{exclude} if($OPTS->{exclude});
	push @exclude,'\.(?:jpg|gif|png|jpeg)' if($OPTS->{'no-images'});
	push @exclude,'\.(?:flv|mov|f4v|avi|mkv|mpg|mpeg|rmvb|asf|wmv|ts|mp4|3pg)' if($OPTS->{'no-videos'});
	if(@exclude) {
		$OPTS->{exclude} = join("|",@exclude);
	}

	if($OPTS->{use}) {
		$OPTS->{input} = $OPTS->{use} . "/urls.lst" unless($OPTS->{input});
		$OPTS->{config} = $OPTS->{use} . "/.mtm" unless($OPTS->{config});
	}
	if($OPTS->{one}) {
		$OPTS->{count} = 1;
	}

	my $mtm = MyPlace::Tasks::Manager->new(
		directory=>$OPTS->{directory},
		worker=>sub {
			return $self->download(@_);
		},
		title=>
			defined($OPTS->{title}) ? $OPTS->{title} : 
			defined($OPTS->{directory}) ? $OPTS->{directory} :
			'<mdown>',
		force=>$OPTS->{force},
		overwrite=>$OPTS->{overwrite},
		retry=>$OPTS->{retry},
		'ignore-failed'=>$OPTS->{'ignore-failed'},
		simple=>$OPTS->{simple},
		'recursive'=>$OPTS->{recursive},
		quiet=>$OPTS->{quiet},
		include=>$OPTS->{include},
		exclude=>$OPTS->{exclude},
		count=>$OPTS->{count},
		'no-queue'=>$OPTS->{'no-queue'},
		'no-download'=>$OPTS->{'no-download'},
		'no-failed'=>$OPTS->{'no-failed'},
		'no-done'=>$OPTS->{'no-done'},
		'no-ignored'=>$OPTS->{'no-ignored'},
		'no-mtm'=>$OPTS->{'no-mtm'},
		'config'=>$OPTS->{'config'},
		'nop'=>$OPTS->{'nop'},
		'print'=>$OPTS->{'print'},
		'select'=>$OPTS->{'select'},
		'mark'=>$OPTS->{'mark'},
	);
	$self->{mtm} = $mtm;
	
	if($OPTS->{input}) {
		$mtm->set('input',$OPTS->{input});
	}
	if($OPTS->{worker}) {
		$mtm->set('worker',$OPTS->{worker});
	}
	return $mtm->run(@_);
}

return 1 if caller;
my $PROGRAM = new MyPlace::Program::Downloader;
my ($done,$error,$msg) = $PROGRAM->execute(@ARGV);
if($error) {
	print STDERR "Error($error): $msg\n";
}
if($done) {
	exit 0;
}
elsif($error) {
	exit $error;
}
else {
	exit 0;
}


1;
__END__

=pod

=head1  NAME

myplace-downloader - PERL script

=head1  SYNOPSIS

myplace-downloader [options] inputs...

	myplace-downloader --force 'http://aliv.weipai.cn/201408/14/16/007F1EF5-0AE5-41B9-950B-97655752B0DA.jpg  2014081416_rococoshop.jpg'
	cat urls.txt | myplace-downloader --overwrite
	myplace-downloader --force --overwrite --input urls.lst

=head1  OPTIONS

=over 12

=item B<-g>,B<--ignore-failed>

Write failed task to DB_IGNORE

=item B<-i>,B<--input>

Read URLs definition from specified file

=item B<-f>,B<--force>

Force download mode, ignore DB_DONE, DB_IGNORE

=item B<-o>,B<--overwrite>

Overwrite download mode

=item B<-t>,B<--title>

Specified prompting text

=item B<-d>,B<--directory>

Specified working directory

=item B<--version>

Print version infomation.

=item B<-h>,B<--help>

Print a brief help message and exits.

=item B<--manual>,B<--man>

View application manual

=item B<--edit-me>

Invoke 'editor' against the source

=back

=head1  DESCRIPTION

Downloader use MyPlace::Tasks::Manager

=head1  CHANGELOG

    2015-01-26 02:34  xiaoranzzz  <xiaoranzzz@MyPlace>

		* version 0.1

    2015-01-26 02:19  xiaoranzzz  <xiaoranzzz@MyPlace>
        
        * file created.

=head1  AUTHOR

xiaoranzzz <xiaoranzzz@MyPlace>

=cut

#       vim:filetype=perl
