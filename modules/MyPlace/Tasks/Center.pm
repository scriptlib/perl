#!/usr/bin/perl -w
use strict;
use warnings;
package MyPlace::Tasks::Center;
use MyPlace::Tasks::Task qw/$TASK_STATUS/;
use File::Spec;
use MyPlace::Script::Message;
use MyPlace::Tasks::Utils qw/strtime/;
use MyPlace::Tasks::File qw/read_tasks/;
my $DEFAULT_TASKS_LEVEL = 10;

sub new {
	my $class = shift;
	my $self = bless {},$class;
	$self->{config} = shift(@_) || $main::MYSETTING;
	$self->{DIR_CONFIG} = $self->{config}->{_DIR};
	$self->{options} = {@_};
	$self->{tasks} = [];
	$self->{pools} = [];
	$self->{tasks_done} = [];
	$self->{tasks_ignored} = [];
	$self->{tasks_error} = [];
	$self->{tasks_donothing} = [];
	$self->{config} = $main::MYSETTING;
	$self->{status} = 'CLEAR';
	$self->load();
	$self->{options}->{sleep} = 60 unless($self->{options}->{sleep});


	$self->{DIR_KEEPS} = $self->C_FILE('keeps');
	if(! -d $self->{DIR_KEEPS}) {
		mkdir $self->{DIR_KEEPS} or print STDERR "Error creating directory: ",$self->{DIR_KEEPS},"\n";
	}

	$self->{FILE_SUMMARY} = $self->C_FILE('SUMMARY.md');
	$self->{FILE_HISTORY} = $self->C_FILE('HISTORY.md');
	$self->{FILE_STATUS} = $self->C_FILE('STATUS.md');
	$self->{FILE_LOCALTASKS} = $self->C_FILE('localtasks');
	unlink $self->{FILE_HISTORY};
	$self->watch(90,$self->{FILE_LOCALTASKS},
		DEBUG=>$self->{DEBUG},
		data => sub {
			my $filename = $self->{FILE_LOCALTASKS};
			return unless (-f $filename);
			my $tasks;
			if($self->{DEBUG}) {
				$tasks = &read_tasks($filename,"",0,1);
			}
			else {
				$tasks = &read_tasks($filename,"",1,1);
			}
			if($tasks and @{$tasks}) {
				return @{$tasks};
			}	
		},
		queue=>1,
		freq=>10,
		ON_TOP=>1,
		level=>80,
	);
	return $self;
}

sub C_FILE {
	my $self = shift;
	return File::Spec->catfile($self->{DIR_CONFIG},@_);
}


sub trace {
	my $self = shift;
	if(!$self->{tracing}) {
		$self->{tracing} = [];
	}
	push @{$self->{tracing}},@_ if(@_);
	return $self->{tracing};
}
sub build_count_exp {
	my $count = shift(@_) || 0;
	my $one = shift(@_);# || " item";
	my $more = shift(@_);# || $one . "s";
	my $prefix = shift(@_) || "";
	my $suffix = shift(@_) || "";
	my $force = shift;
	unless($force || $count) {
		return ();
	}
	if($count > 1) {
		return "$prefix$count$more$suffix";
	}
	else {
		return "$prefix$count$one$suffix";
	}
}

sub status_update {
	my $self = shift;
	
	
	return unless($self->{counter});
	my $total = 0;
	foreach(keys %{$self->{counter}}) {
		$total += $self->{counter}{$_} if($self->{counter}{$_});
	}
	if(!$total) {
		return undef;
	}

	my $tasks_summary = join(", ",
		build_count_exp(
			$self->{counter}{$TASK_STATUS->{FINISHED}},"","","",
			" Done",1
		),
		build_count_exp(
			$self->{counter}{$TASK_STATUS->{ERROR}},"","","",
			" Error"
		),
		build_count_exp(
			$self->{counter}{$TASK_STATUS->{DONOTHING}},"","","",
			" Doing nothing"
		),
		build_count_exp(
			$self->{counter}{$TASK_STATUS->{IGNORED}},"","","",
			" Ignored"
		)
	);
	
if(!$self->{DEBUG}) {
	my $output = $self->{FILE_STATUS};
	if(open FO,'>',$output) {
		print FO "Tasks Status Report\n";
		print FO "============\n\n";
		print FO join("\n",$self->status),"\n";
		close FO;
	}
	else {
		app_error("[" . strtime() . "] Error opening <$output> for writting\n");
	}
}
	app_warning "Tasks: $tasks_summary\n";
	return $tasks_summary;

}

sub status {
	my $self = shift;
	my @text;
	
	if($self->{last_task}) {
		push @text, '* Working on:';
		push @text, '    * [' . strtime($self->{last_task}->{time_begin}) . "] " . $self->{last_task}->to_string;
	}
	if($self->{tasks} and @{$self->{tasks}}) {
		my $count = $self->more();
		push @text, "* Pendings $count tasks.";
	}
	if($self->{tasks_done} and @{$self->{tasks_done}}) {
		push @text, "* Finished:";
		push @text, "    * [" . strtime($_->{time_end})  . "] " . $_->to_string foreach(reverse @{$self->{tasks_done}});
	}
	if($self->{tasks_donothing} and @{$self->{tasks_donothing}}) {
		push @text, "* Doing Nothing:";
		push @text, "    * [" . strtime($_->{time_end})  . "] " . $_->to_string foreach(reverse @{$self->{tasks_donothing}});
	}
	if($self->{tasks_ignored} and @{$self->{tasks_ignored}}) {
		push @text, "* Ignored:";
		push @text, "    * "  . $_->to_string foreach(reverse @{$self->{tasks_ignored}});
	}
	if($self->{tasks_error} and @{$self->{tasks_error}}) {
		push @text, "* Error:";
		push @text, "    * "  . $_->to_string foreach(reverse @{$self->{tasks_error}});
	}
	return @text;
}


sub runonce {
	my $self = shift;
	$self->{runonce} = 1;
	if(@_) {
		$self->queue(MyPlace::Tasks::Task->new(@_));
	}
}

sub watch {
	my $self = shift;
	my $level = shift;
	my $name = shift;
	use MyPlace::Tasks::Pool;
	my $pool = MyPlace::Tasks::Pool->new($name,@_);
	$self->{TASKS_POOL_COUNT} += 1;
	if($self->{ignore}) {
		$pool->{ignore} = $self->{ignore} unless($pool->{ignore});
	}
	if($pool->{disabled}) {
		app_message "Tasks pool of [$name] disabled, IGNORED!\n";
		return;
	}
	if(!$self->{pools}->[$level]) {
		$self->{pools}->[$level] = [];
	}
	push @{$self->{pools}->[$level]},$pool;
	app_message "Start watching tasks pool of [$name] ...\n";
	return;
}

sub more {
	my $self = shift;
	$self->{called_sub_more} += 1;
	my $count = 0;
	my $POOLS = $self->{pools};
	my $TASKS = $self->{tasks};
	for my $level (reverse 0 .. 100) {
		last if($TASKS->[$level] and @{$TASKS->[$level]});
		next unless($POOLS->[$level] and @{$POOLS->[$level]});
		foreach my $builder(@{$POOLS->[$level]}) {
			my @t = $builder->more($self->{TASKS_POOL_EMPTY});
			if(@t) {
				my $nextlevel = $builder->{level} || ($level);
				my @queue;
				foreach(@t) {
					next unless($_);
					next unless(ref $_);
					push @queue,$_;
					print STDERR "#L" . $nextlevel . "# Queuing< " . $_->to_string . "\n";
				}
				$self->queue($nextlevel,\@queue,$builder->{ON_TOP}) if(@queue);
			}
		}
		last if($TASKS->[$level] and @{$TASKS->[$level]});
	}
	for my $level (reverse 0 .. 101) {
		next unless($self->{tasks}->[$level]);
		$count += scalar(@{$self->{tasks}->[$level]});
	}
	$self->{TASKS_POOL_EMPTY} = 0;
	if($count>0) {
		return $count;
	}
	elsif($self->{runonce}) {
		return 0;
	}
#	elsif($self->read_localfile) {
#		return $self->more();
#		#scalar(@{$self->{tasks}});
#	}
	elsif($self->{called_sub_more} > 1) {
		sleep $self->{options}->{sleep} if($self->{options}->{sleep});
	}
	$self->{TASKS_POOL_EMPTY} = 1;
	return 0;
}


sub next {
	my $self = shift;
	my $task;
	my $tasks = $self->{tasks};
	return unless($tasks and @$tasks);
	for my $level(reverse 0 .. 101) {
		next unless($tasks->[$level] and @{$tasks->[$level]});
		$task = shift(@{$tasks->[$level]});
		$task->{level} = $level;
		last;
	}
	return unless($task);
	$self->{last_task} = $task;
	$self->{status} = 'NEXT';
	return $task;
}

sub queue {
	my $self = shift;
	my $level = shift;

	return unless(defined $level);
	if($level =~ m/^\s*(\d+)\s*$/) {
		$level = $1;
	}
	else {
		unshift @_,$level;
		$level = undef;
	}

	my $task = shift;
	return unless($task);



	my $ontop = shift;
	
	my @tasks;

	my $TASK_TYPE = ref $task;

	if(!$TASK_TYPE) {
		$task = MyPlace::Tasks::Task->new_from_string($task);
		push @tasks,$task;
	}
	elsif($TASK_TYPE eq 'ARRAY') {
		@tasks = (@{$task});
		$level = $tasks[0]->{level} if((!defined $level) and (defined $tasks[0]->{level}));
	}
	else {
		push @tasks,$task;
		$level = $task->{level} if((!defined $level) and (defined $task->{level}));
	}

	return unless(@tasks);

	$level = $DEFAULT_TASKS_LEVEL if(!defined $level);
	$level = int($level);
	$level = 0 if($level < 0);
	$level = 100 if($level > 100);
	
	$self->{tasks} = [] unless($self->{tasks});
	$self->{tasks}->[$level] = [] unless($self->{tasks}->[$level]);
	if($ontop) {
		unshift @{$self->{tasks}->[$level]},@tasks;
	}
	else {
		push @{$self->{tasks}->[$level]},@tasks;
	}
	return $self;
}

sub abort {
	my $self = shift;
	my $task = $self->{last_task};
	if($task) {
		$task->{status} = $TASK_STATUS->{'IGNORE'};
		$self->queue($task->{level} || $DEFAULT_TASKS_LEVEL,$task,1);
	}
	$self->{last_task} = undef;
	$self->save();
	return 0;
}

sub finish {
	my $self = CORE::shift;
	my $task = shift;
	my $status = $task->{status};

	$self->{counter}{$status} = 0 unless($self->{counter}{$status});
	$self->{counter}{$status}++;

	if($status == $TASK_STATUS->{'IGNORED'} || $status == $TASK_STATUS->{PENDING}) {
		app_warning("Task ignored: No listener for [",$task->namespace,"]\n");
		push @{$self->{tasks_ignored}},$task;
	}
	elsif($status == $TASK_STATUS->{'FINISHED'}) {
		push @{$self->{tasks_done}},$task;
	}
	elsif($status == $TASK_STATUS->{'ERROR'}) {
		push @{$self->{tasks_error}},$task;
	}
	elsif($status == $TASK_STATUS->{'DONOTHING'}) {
		push @{$self->{tasks_donothing}},$task;
	}
	elsif($status == $TASK_STATUS->{'NEWTASKS'}) {
		$self->queue($task->{result},1) if($task->{result});
	}
	
	if($task->tasks) {
		foreach($task->tasks) {
			$self->queue(@$_);
		}
	}
	$self->{last_task} = undef;
	$self->save();
	$self->log_task_finished($task);
	$self->status_update($task);
	$self->{status} = 'CLEAR';
}

sub file_changed {
}

sub _summary_task {
	my $task = shift;
	my $r = "* " . $task->to_string . "\n\n";
	$r .= "    * Begin : " . strtime($task->{time_begin}) . "\n" if($task->{time_begin});
	$r .= "    * End   : " . strtime($task->{time_end}) . "\n" if($task->{time_end});
	$r .= "    * Result: " . ($task->{summary} || $task->status) . "\n\n";
	return $r;
}
sub _prepend_file {
	my $self = shift;
	my $output = shift;
	my $newtext = shift;
	my $maxlines = shift(@_) || 0;
	my @text;
	if(-f $output and open FI,'<',$output) {
		@text = <FI>;
		close FI;
	}
	if($maxlines) {
		my $lines = scalar(@text);
		if($lines > $maxlines) {
			my $saved = $output;
			$saved =~ s/^.*[\/\\]//;
			my $datestr = strtime(time(),undef,"","","");
			if($saved =~ m/\.[^\/\\\.]+$/) {
				$saved =~ s/\.([^\/\\\.]+)$/_$datestr.$1/;
			}
			else {
				$saved = $saved . "_" . $datestr;
			}
			$saved = File::Spec->catfile($self->{DIR_KEEPS},$saved);
			if(rename($output,$saved)) {
				app_message2 "Backup $output \n\t==> $saved\n";
				@text = ();
			}
		}
	}	
	if(open FO,'>',$output) {
		print FO $newtext;
		print FO @text;
		close FO;
		return 1;
	}
	else {
		app_error("[" . now() . "] Error opening <$output> for writting\n");
		return undef;
	}
}
sub log_task_finished {
	my $self = shift;
	my $task = shift;
	return unless($task);
if(!$self->{DEBUG}) {	
	my $summary = _summary_task($task);
	$self->_prepend_file($self->{FILE_HISTORY},$summary,0);
	if($task->{status} == $TASK_STATUS->{FINISHED}) {
		$self->_prepend_file($self->{FILE_SUMMARY},$summary,1000);
	}
}
	return;
}

sub failed {
	my $self = CORE::shift;
	my $task  = CORE::shift;
	my $retry = CORE::shift;
	$self->log_task_failed($task);
	if($retry) {
		$self->unshift($task);
	}
	return $self;
}

sub exit {
	my $self = shift;
	my $task = $self->{last_task};
	if($task) {
		if(!$task->{status}) {
			$self->queue($task->{level} || $DEFAULT_TASKS_LEVEL,$task,1);
		}
		elsif($task->{status} == 2) {
			$self->queue($task->{level} || $DEFAULT_TASKS_LEVEL,$task,1);
		}
		else {
		}
		$self->log_task_finished($task);
	}
	$self->status_update($task,1);
	$self->{last_task} = undef;
	$self->save();
	return 0;
}

sub end {
	return undef;
}

sub save {
	my $self = CORE::shift;
	return unless($self->{config});
	if($self->{DEBUG}) {
		app_warning "DEBUG MODE: Configuration not save!\n";
		return;
	}
	my $sec = "Tasks::Center";
	delete $self->{config}->{$sec . "::tasks"};
	foreach my $level(reverse 0 .. 100) {
		next unless($self->{tasks}->[$level]);
		$self->{config}->{$sec . "::tasks$level"} = [];
		#	print STDERR "Saveing Tasks [$level] ...\n";
		foreach (@{$self->{tasks}->[$level]}) {
			my $text = $_->save();
			#	print STDERR " ... $text\n";
			push @{$self->{config}->{$sec . "::tasks$level"}},$text;
		}	
	}
	foreach(keys %{$self->{options}}){
		$self->{config}->{$sec. "::options.$_"} = $self->{options}->{$_};
	}
}

sub load {
	my $self = CORE::shift;
	return unless($self->{config});
	my $sec = "Tasks::Center";
	if($self->{config}->{$sec . "::tasks"}) {
		$self->{tasks}->[$DEFAULT_TASKS_LEVEL] = [];
		foreach(@{$self->{config}->{$sec . "::tasks"}}) {
			next unless($_);
			my $task = MyPlace::Tasks::Task->new_from_string($_);
			#	print STDERR $_,"\n";
			push @{$self->{tasks}->[$DEFAULT_TASKS_LEVEL]},$task;
		}
	}
	foreach my $level (reverse 0 .. 100) {
		next unless $self->{config}->{$sec . "::tasks$level"};
		$self->{tasks}->[$level] = [];
		foreach(@{$self->{config}->{$sec . "::tasks$level"}}) {
			next unless($_);
			push @{$self->{tasks}->[$level]},MyPlace::Tasks::Task->new_from_string($_);
		}
	}
	foreach (keys %{$self->{config}}) {
		if(m/$sec\:\:options.([^\s]+)$/) {
			$self->{options}->{$1} = $self->{config}->{$_};
		}
	}
#	use Data::Dumper;
#	print STDERR Data::Dumper->Dump([$self->{tasks}],['*tasks']),"\n";
#	die();
}

sub ignore {
}



1;

