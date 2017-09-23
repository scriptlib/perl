#!/usr/bin/perl -w
package MyPlace::Tasks::Processer;
use strict;
use warnings;
use utf8;
use MyPlace::File::Utils qw/file_write/;

sub new {
	my $class = shift;
	my $self = bless {},$class;
	$self->init(@_);
	return $self;
}

sub init {
	my $self = shift;
	$self->{store} = {
		@_,
	};
	$self->{name} = $self->{store}->{name};
	return $self;
}

sub output {
	my $self = shift;
	print STDERR (
		($self->{name} ? $self->{name} : 'Tasks Processer'),
		'>',
		"\n  ",
		join(" ",@_)
	);
}

sub _init_store {
	my $self = shift;
	my $store = $self->{store} || {};
	$store->{config} ||= ".listener";
	$store->{threads} ||= 3;
	$store->{file_input} ||= $store->{config} . "/local";
	$store->{file_free} ||= $store->{config} . "/free";
	$store->{tasks} ||= $store->{config} . "/feeds";
	$store->{quickload} ||= $store->{config} . "/quickload";
	$store->{wait} ||= 1;
	$self->{store} = $store unless($self->{store});
	return $self->{store};
}

sub _listener_get_free {
	my $self = shift;
	my $store = $self->{store};
	my $LN_DIR = $store->{config};
	my $LN_FREE_FILE = $store->{file_free};
	my $count = shift;
	for(1 .. $count) {
		if(-f $LN_FREE_FILE . $_) {
			unlink $LN_FREE_FILE . $_;
			return $_;
		}
	}
	return undef;
}

sub _listener_set_free {
	my $self = shift;
	my $store = $self->{store};
	my $LN_FREE_FILE = $store->{file_free};
	my $id = shift;
	return 1 if(-f $LN_FREE_FILE . $id);
	file_write($LN_FREE_FILE . $id);
	return 1;
}

sub _listener_is_free {
	my $self = shift;
	my $store = $self->{store};
	my $LN_FREE_FILE = $store->{file_free};
	my $id = shift;
	return 1 if(-f $LN_FREE_FILE . $id);
}

sub _listener_fork {
	my $self = shift;
	my $store = $self->{store};
	my $LN_FREE_FILE = $store->{file_free};
	my $LN_FILE = $store->{file_input};
	my $id = shift;
	unlink $LN_FREE_FILE . $id;
	file_write($LN_FILE . $id,'>>',join(" ",@_),"\n");
}

sub start_listener {
	my $self = shift;
	my $store = $self->_init_store;
	my $helper = $store->{helper};
	if(!$helper) {
		foreach(@INC) {
			if(-f "$_/MyPlace/Tasks/Helper.pl") {
				$helper = "$_/MyPlace/Tasks/Helper.pl";
				last;
			}
		}
		if($helper) {
			$store->{helper} = $helper;
			$self->output( "Use listener helper <$helper>\n");
		}
		else {
			$helper = "./helper.pl";
		}
	}
	
	my $index = shift;
	$self->output( "Start listener [$index]\n");
	unlink $store->{file_input} . $index;
	$self->_listener_set_free($index);
	system(
		'mintty_bg', 
		$helper,
		$index,
		$store->{worker},
		$store->{file_input} . $index,
		$store->{file_free} . $index,
		($store->{wait2} || $store->{wait}),
	) == 0;
}
sub read_tasks {
	my $self= shift;
	my $FEED = shift;
	my @lists;
	my $status = shift;
	my %opts = @_;
	open FI,'<',$FEED or return @lists;
	if($status) {
		$self->output("Reading from $FEED... ");
	}
	while(<FI>) {
		chomp;
		next if(m/^[\r\n\s]*$/);
		next if(m/^\s*#/);
		push @lists,$_;
	}
	close FI;
	print STDERR " [OK] \n\t" . scalar(@lists)," tasks read\n" if($status);
	if($opts{delete}) {
		$self->output("Delete file $FEED\n") if($status);
		unlink $FEED;
	}
	return @lists;
}

sub checkTime {
	my $self = shift;
	my $print = shift;
	my $now = time();
	my $shutdown = undef;
	my $end = undef;
	if(!$self->{time_started}) {
		$self->{time_started} = $now;
	}
	$self->{time_lasted} = int(($now - $self->{time_started}) / 60);
	if(!$self->{time_checked}) {
		$self->{time_checked} = $now;
	}
	elsif($now - $self->{time_checked} > 60) {
		$print = 1;
	}
	
	if($self->{store}->{shutdown}) {
		$shutdown = 1;
		if($self->{time_lasted} >= $self->{store}->{shutdown}) {
			$end = 1;
		}
	}
	if($print || $end) {
		my $text = "Program'd been lasted for " . $self->{time_lasted} . " minutes\n";
		if($shutdown) {
			$text .= "  It'll be shutdown in " . ($self->{store}->{shutdown}-$self->{time_lasted}) . " minutes\n";
		}
		$self->output($text);
		$self->{time_checked} = $now;
	}
	if($end) {
		$self->output("Program ABORTING ...\n");
		return undef;
	}
	return 1;
}

sub run {
	my $self = shift;
	my $store = $self->_init_store;
	my $LN_DIR = $store->{config};
	my $LN_COUNT = $store->{threads};
	my $LN_FILE = $store->{file_input};
	my $LN_FREE_FILE = $store->{file_free};
	
	for(1 .. $LN_COUNT) {
		$self->start_listener($_);
	}
	
	my $FEED = $store->{tasks};
	my $wait = $store->{wait1} || $store->{wait};
	my %dup;
	my @running;
	while($wait) {
		return $self->free() unless($self->checkTime);
		my @lists = $self->read_tasks($FEED,1);
		my $count = scalar(@lists);
		my $index = 1;
		if($store->{shuffle}) {
			use List::Util qw/shuffle/;
			@lists = shuffle(@lists);
		}
		my $next_task;
		my @quicktasks = $self->read_tasks($store->{quickload},1,'delete'=>1);
		my $qcount = scalar(@quicktasks);
		$next_task = shift(@quicktasks) || shift(@lists);
		while($next_task) {
			return $self->free() unless($self->checkTime);
			local $_ = $next_task;
			my $text = $_;
			$text =~ s/[\t\s]+/ /g;
			$self->output( "[$index/" . ($count+$qcount) . "]Processing <$text>\n");
			$index++;
			if($dup{$_}) {
				$self->output( "Task is running, Ignored\n");
				next;
			}
			if($_ eq 'END') {
				$self->output( "END signal recieved, EXIT\n");
				return 0;
				last;
			}
			my $free = undef;
			my $try_2 = undef;
			while(!$free) {
				return $self->free() unless($self->checkTime);
				$free = $self->_listener_get_free($LN_COUNT);
				if(!$free) {
					if(!$try_2) {
						for my $id(1 .. $LN_COUNT) {
							if(defined $running[$id]) {
								print STDERR "[$id] $running[$id]\n";
							}
						}
						$self->checkTime(1);
						$self->output( "Listeners all busy, waiting...\n");
					}
					$try_2 = 1;
					sleep $wait;
				}
			}
			if(defined $store->{preprocess}) {
				if(!$store->{preprocess}->($_)) {
					$self->output( "Pre-Process failed, NEXT\n");
					$self->_listener_set_free($free);
					next;
				}
			}
			delete $dup{$running[$free]} if($running[$free]);
			$self->output( "Dispatch task <$text> to Listener [$free]\n");
			$running[$free] = $_;
			$dup{$_} = 1;
			$self->_listener_fork($free,$_);
		}
		continue {
			if(!@quicktasks) {
				@quicktasks = $self->read_tasks($store->{quickload},1,'delete'=>1);
			}
			$qcount = scalar(@quicktasks);
			$next_task = shift(@quicktasks) || shift(@lists);
		}
	} continue {
		foreach(1 .. $LN_COUNT) {
			if($self->_listener_is_free($_)) {
				delete $dup{$running[$_]} if($running[$_]);
			}
		}
		$self->output( "Waiting for $FEED ...\n");
		sleep $wait;
	}
}

sub free {
	my $self=  shift;
	my $store = $self->{store};
	my $LN_COUNT = $store->{threads};
	for my $free(1 .. $LN_COUNT) {
		$self->_listener_fork($free,'END');
	}
	return 1;
}

1;
