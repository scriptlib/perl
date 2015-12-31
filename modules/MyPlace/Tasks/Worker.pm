#!/usr/bin/perl -w
package MyPlace::Tasks::Worker;
use strict;
use warnings;
use MyPlace::Tasks::Task qw/$TASK_STATUS/;
use MyPlace::Script::Message;
use Cwd qw/getcwd/;

sub new {
	my $class = shift;
	my $self = bless {@_},$class;
	return $self;
}
sub error {
	my $self = shift;
	my $task = shift;
	my $WD = $task->{target_dir} || $task->{workdir} || $self->{target_dir} || ".";
	my $msg = shift;
	my $NOTLOG = shift;
	if((!$NOTLOG) and open(my $FO,">>",catfile($WD,'errors.log'))) {
		print $FO $task->to_string(),"\n";
		print $FO "\t$msg\n";
		close $FO;
	}
	return $TASK_STATUS->{ERROR},$msg;
}

sub dump_info {
	my $self = shift;
	my $task = shift;
	print "="x40,"\n";
	print "Directory: ",getcwd,"\n";
	print "Task: ", $task->to_string,"\n";
	print "="x40,"\n";
	return $TASK_STATUS->{DONOTHING};

}

sub set_workdir {
	my $self = shift;
	my $task = shift;
	my $WD = shift;
	my $r;
	if($WD) {
		app_message2 "Directory: $WD\n";
		my $EWD;
		unless(-d $WD or mkdir $WD) {
			$EWD = 1;
			$r = $TASK_STATUS->{ERROR};
			$task->{summary} = "Error creating directory $WD:$!";
		}
		unless($EWD or chdir $WD) {
			$EWD = 1;
			$r = $TASK_STATUS->{ERROR};
			$task->{summary} = "Error changing directory to $WD:$!";
		}
		if($EWD) {
			app_error $task->{summary},"\n";
			if($WD eq $self->{workdir}) {
				$r = $TASK_STATUS->{FATALERROR};
				#app_error "Error, Worker [$self->{name}] works in invalid directory: $WD\n";
				return $r;
			}
			return $r;
		}
	}
	return undef;
}

sub do_task {
	my $self = shift;
	my $task = shift;
	my @content = @_;
	my ($r,$s) = $self->{routine}->($self,$task,@content);
	if(!$r) {
		$task->{status} =  $TASK_STATUS->{FINISHED};
	}
	else {
		$task->{status} = $r;
	}
	if($s) {
		if(ref $s) {
			$task->{result} = $s;
#			$self->process_result($task,@$s);
		}
		else {
			$task->{summary} = $s;
		}
	}
	return $task->{status};
}

sub process {
	my $self = shift;
	my $task = shift;
	$task->{time_begin} = time;
	my $r;
	$r = $self->set_workdir($task,$task->{workdir} || $self->{workdir});
	return $r if($r);
	$self->do_task($task,$task->content());
	$task->{time_end} = time;
	return $task->{status};
}

sub process_result {
	my $self = shift;
	my $task = shift;
	foreach my $r (@_) {
		if(ref $r) {
		}
	}
}

1;

