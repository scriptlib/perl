#!/usr/bin/perl -w
# $Id$
use warnings;
use strict;

our $VERSION = 'v0.2';
my @OPTIONS = qw/
	help|h|? 
	manual|man
	start
	stop
	sleep=i
	no-git
	no-pull
	debug
	no-push
/;
my %OPTS;
if(@ARGV)
{
    require Getopt::Long;
    Getopt::Long::GetOptions(\%OPTS,@OPTIONS);
}
if($OPTS{'help'} or $OPTS{'manual'}) {
	require Pod::Usage;
	my $v = $OPTS{'help'} ? 1 : 2;
	Pod::Usage::pod2usage(-exitval=>$v,-verbose=>$v);
    exit $v;
}


use MyPlace::SimpleConfig qw/sc_from_file sc_to_file/;
use MyPlace::Script::Message;
use MyPlace::Tasks::Utils qw/strtime/;
use MyPlace::Tasks::Center::Git;
use MyPlace::Tasks::Builder;
use MyPlace::Tasks::Listener;
use MyPlace::Tasks::Worker;
use MyPlace::Tasks::Task qw/$TASK_STATUS/;
use Cwd qw/getcwd/;



my $CONFIGURATION = ".myplace/tasks-daemon.config";
our $MYSETTING = sc_from_file($CONFIGURATION);

my $TASKER;
if(!$OPTS{"no-git"}) {
	$TASKER = MyPlace::Tasks::Center::Git->new();
}
else {
	$TASKER = MyPlace::Tasks::Center->new();
}
$TASKER->ignore('follows\.(txt|md)$',"^ladies");
$TASKER->trace('ladies');
if($ENV{DEBUG} || $OPTS{'debug'}) {
	$TASKER->{DEBUG} = 1;
}
foreach (qw/sleep no-pull no-push/) {
	$TASKER->{options}{$_} = $OPTS{$_} if(defined $OPTS{$_});
}

my $START_DIR = getcwd;
my $TasksBuilder = MyPlace::Tasks::Builder->new();
my @DEFAULT_LISTENERS = (
		MyPlace::Tasks::Listener->new('dump', 
			MyPlace::Tasks::Worker->new(
					name=>'dump',
					routine=>sub{
						use Data::Dumper;
						print Data::Dumper->Dump(\@_);
						return $TASK_STATUS->{DONOTHING};
					}
			)
		),
		MyPlace::Tasks::Listener->new('echo', 
			MyPlace::Tasks::Worker->new(
					name=>'echo',
					routine=>sub{
						print join(" ",@_),"\n";
						return $TASK_STATUS->{DONOTHING};
					}
			)
		),
);



use Cwd qw/getcwd/;

sub abort {
	delete $SIG{INT};
	chdir $START_DIR;
	$TASKER->abort();
	app_error "X"x10 . " PROGRAM KILLED!!! " . "X"x10 ."\n";
	sc_to_file($CONFIGURATION,$MYSETTING);
	exit $TASKER->exit();
}
$SIG{INT} = \&abort;

app_warning "[" . strtime() . "] Start\n";
app_warning "Directory: $START_DIR\n";

do ".myplace/listener";
my @LISTENER = (
		@DEFAULT_LISTENERS,
		listener_init($TASKER,$TasksBuilder)
);
app_warning scalar(@LISTENER) . " listener initilized\n";
foreach(@LISTENER) {
	app_warning "Listen to namespace [" . $_->{namespace} . "]\n";
}
print STDERR "\n";

my $count =0;
while(!$TASKER->end()) {
	app_message2 "[" . strtime() . "] Waiting for event\n";
	my $task;
	my $last_task;
	my $remain;
	if ($remain = $TASKER->more()) {
		$last_task = $task;
		$task = $TASKER->next();
		$TASKER->{status} = 'RUNNING';
		app_warning "Tasks $count DONE, $remain REMAIN:\n";
		app_warning "Working on task:\n";
		app_warning " * " . $task->to_string . "\n";
		$count++;
		my $fired;
		foreach my $listener (@LISTENER) {
			if($listener->check($task)) {
				$fired = 1;
				$listener->fire_event($task);
				chdir $START_DIR;
			}
		}
		$task->{status} = $TASK_STATUS->{IGNORED} unless($fired);
		$TASKER->finish($task);
	}
	elsif($TasksBuilder->more()) {
		app_message2 "[" . strtime() . "] Queuing scheduled task\n";
		$TASKER->queue($TasksBuilder->next());
	}
} 
sc_to_file($CONFIGURATION,$MYSETTING);
exit $TASKER->exit();



























#	vim:filetype=perl



__END__

=pod

=head1  NAME

myplace-tasks-daemon - PERL script

=head1  SYNOPSIS

myplace-tasks-daemon [options] ...

=head1  OPTIONS

=over 12

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

___DESC___

=head1  CHANGELOG

    2014-08-30 01:29  xiaoranzzz  <xiaoranzzz@MyPlace>
        
        * file created.

=head1  AUTHOR

xiaoranzzz <xiaoranzzz@MyPlace>

=cut

#       vim:filetype=perl
