#!/usr/bin/perl -w
package MyPlace::Tasks::Listener;
use strict;
use warnings;
use MyPlace::Script::Message;
sub new {
	my $class = shift;
	my $namespace = shift;
	my $worker = shift;
	return bless {namespace=>$namespace,worker=>$worker},$class;
}

sub check {
	my $self = shift;
	my $task = shift;
	#print STDERR "Listener [" . $self->{namespace} . "] Checking task ...";
	return $self->{namespace} eq $task->{namespace};
#	if($r) {
#		print STDERR " [OK]\n";
#	}
#	else {
#		print STDERR " [No supported]\n";
#	}
#	return $r;
}

use MyPlace::Tasks::Task qw/$TASK_STATUS/;

sub fire_event {
	my $self = shift;
	my $task = shift;
	my @r =  $self->{worker}->process($task);
	my $report = " * [" . $self->{worker}->{name} . "] " . 
			($task->{summary} ? $task->{summary}  : $task->status) . 
			"\n";
	if($task->{status} == $TASK_STATUS->{ERROR}) {
		app_error $report;
	}
	elsif($task->{status} == $TASK_STATUS->{DONOTHING}) {
		app_message2 $report;
	}
	elsif($task->{status} == $TASK_STATUS->{NEWTASKS}) {
		return @r;
	}
	else {
		app_warning $report;
	}
	return @r;
}

1;

