#!/usr/bin/perl -w
package MyPlace::Program::Saveurl;
use strict;
use warnings;

use MyPlace::Script::Message;
use Getopt::Long;
use MyPlace::Downloader;
my $MSG = MyPlace::Script::Message->new('saveurl');

sub parse_options {
	my @OPTIONS = qw/
	help|h|? 
	manual|man
	referer|r=s
	base|b=s
	overwrite|f
	history|hist
	no-http|nh
	no-qvod|nq
	no-ed2k|ne
	no-bdhd|nb
	no-file|nf
	no-data|nd
	no-torrent|nt
	no|n=s
	thread|t=i
	output|o=s
	include|I=s
	exclude|X=s
	/;
	my %OPTS;
	Getopt::Long::Configure('no_ignore_case');
	Getopt::Long::GetOptionsFromArray(\@_,\%OPTS,@OPTIONS);
	return \%OPTS,@_;
}


sub cathash {
	my $lef = shift;
	my $rig = shift;
	return $lef unless($rig);
	return $lef unless(%$rig);
	my %res = $lef ? %$lef : ();
	foreach(keys %$rig) {
		$res{$_} = $rig->{$_} if(defined $rig->{$_});
	}
	return \%res;
}

sub setOptions {
	my $self = shift;
	my ($opts,@remains) = parse_options(@_);
	$self->addTask(@remains) if(@remains);
	return @remains if(!$opts);
	if($self->{OPTS}) {
		$self->{OPTS} = cathash($self->{OPTS},$opts);
	}
	else {
		$self->{OPTS} = $opts;
	}
	return @remains;
}

sub addTask {
	my $self = shift;
	push @{$self->{Tasks}},@_ if(@_);
	#print STDERR join("\n",@{$self->{Tasks}}),"\n";
	return $self->{Tasks};
}
sub addTaskFromFile {
	my $self = shift;
	my $file = shift;
	my $GLOB = ref $file;
	my $fh;
	if($GLOB eq 'GLOB') {
		$GLOB = 1;
	}
	else {
		$GLOB = 2;
	}
	if($GLOB) {
		$fh = $file;
	}
	elsif(!open $fh,"<",$file) {
	#elsif(!open $fh,"<:utf8",$file) {
		app_error("(line " . __LINE__ . ") Error opening $file:$!\n");
		return undef;
	}
	my $count = 0;
	my @tasks = ();
	while(<$fh>) {
	    chomp;
	    s/^\s+//;
	    s/\s+$//;
	    if(!$_) {
	        next;
	    }
		$self->addTask($_);
	}
	close $fh unless($GLOB);
	return $self->{Tasks};
}

sub new {
	my $class = shift;
	my $self = bless {},$class;
	$self->{Tasks} = [];
	$self->{OPTS} = {};
	$self->setOptions(@_) if(@_);
	return $self;
}

sub execute {
	my $self = shift;	
	$self->setOptions(@_);
	my $OPTS = $self->{OPTS};
	if($OPTS->{'help'} or $OPTS->{'manual'}) {
		require Pod::Usage;
		my $v = $OPTS->{'help'} ? 1 : 2;
		Pod::Usage::pod2usage(-exitval=>$v,-verbose=>$v);
		exit $v;
	}
	$self->doTasks();
	return 0;
}


sub doTasks {
	my $self = shift;
	my %OPTS = %{$self->{OPTS}};
	my $tasks = $self->{Tasks};
	if(!($tasks && @{$tasks})) {
		$MSG->warn("No tasks to save\n");
		return 1;
	}
	my $idx = 0 ;
	my $count = scalar(@{$tasks});
	my @lines;
	my $FH_OUT;
	if($self->{OPTS}->{output}) {
		if(!open($FH_OUT,">>",$self->{OPTS}->{output})) {
			$MSG->error("Error opening " .
				$self->{OPTS}->{output} .
				":$!\n"
			);
			return 1;

		}
	}
	while($idx < $count) {
		$idx++;
		my $_ = shift(@{$tasks});
		my $proto = "http";
		if($_ =~ m/^([^:\/]+):\/\//) {
			$proto = $1;
		}
		if($self->{OPTS}->{"no-$proto"} || (
				$self->{OPTS}->{no} && 
				$self->{OPTS}->{no} eq $proto
			) || (
				$self->{OPTS}->{only} &&
				!($self->{OPTS}->{only} eq $proto)
			)
		) {
			$MSG->warn("Skip URL TYPE [$proto]: $_\n");
			next;
		}
		if($self->{OPTS}->{output}) {
			print STDERR "[$idx/$count] " .
				$self->{OPTS}->{output} . 
				"<<$_\r";
			print $FH_OUT $_;
			next;
		}
		if($self->{OPTS}->{include}) {
			if(m/$self->{OPTS}->{include}/) {
			}
			else {
				print STDERR "[NOT Included] Skipped $_\n";
				next;
			}
		}
		if($self->{OPTS}->{exclude}) {
			if(m/$self->{OPTS}->{exclude}/) {
				print STDERR "[Excluded] Skipped $_\n";
				next;
			}
		}
		s/[\r\n]+/ /g;
		push @lines,$_;
	}
	if($self->{OPTS}->{output}) {
		print STDERR "\n";
		close $FH_OUT;
		return $count;
	}

	my $D = scalar(@lines);
	return 1 unless($D);
	my $dld = new MyPlace::Downloader;
	$dld->{OPTS} = $self->{OPTS};
	$idx = 1;
	foreach(@lines) {
		print STDERR " [$idx/$D]";
		$dld->download($_);
		$idx++;
	}
	return $count;
}

return 1 if caller;
my $PROGRAM = new(__PACKAGE__);
exit $PROGRAM->execute(@ARGV);

