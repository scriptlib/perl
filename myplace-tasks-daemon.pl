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

use File::Spec;
use MyPlace::SimpleConfig qw/sc_from_file sc_to_file/;
use MyPlace::Script::Message;
use MyPlace::Tasks::Utils qw/strtime/;
use MyPlace::Tasks::Center::Git;
use MyPlace::Tasks::Builder;
use MyPlace::Tasks::Listener;
use MyPlace::Tasks::Worker;
use MyPlace::Tasks::Task qw/$TASK_STATUS/;
use Cwd qw/getcwd/;

if($ENV{DEBUG} || $OPTS{'debug'}) {
	$OPTS{'debug'} = 1;
}

our $CONFIGDIR = '.mtd';
if(! -d $CONFIGDIR) {
	mkdir $CONFIGDIR or die("Error creating directory [$CONFIGDIR]:$!\n");
}

our $CONFIGURATION = File::Spec->catdir($CONFIGDIR,"config");
our $MYSETTING = sc_from_file($CONFIGURATION);


$MYSETTING->{_DIR} = $CONFIGDIR;
print STDERR "CONFIG : $CONFIGDIR\n" if($OPTS{debug});

my $TASKER;
if(!$OPTS{"no-git"}) {
	app_message "Checking GIT ... \n";
	if(system('git','--version') == 0) {		
		$TASKER = MyPlace::Tasks::Center::Git->new($MYSETTING);
	}
	else {
		app_message "No GIT found, disable GIT\n";
		$TASKER = MyPlace::Tasks::Center->new($MYSETTING);		
	}
}
else {
	$TASKER = MyPlace::Tasks::Center->new($MYSETTING);
}
$TASKER->{DEBUG} = 1 if($OPTS{debug});

my $F_LOG = File::Spec->catfile($CONFIGDIR,"mtd.log");
my $FH_LOG;
open $FH_LOG,'>>',$F_LOG or die("Error opening file [$F_LOG]:$!\n");

my $F_IGNORE = File::Spec->catfile($CONFIGDIR,'ignore');
$MYSETTING->{_IGNORE} = $F_IGNORE;
if(open my $FI,'<',$F_IGNORE) {
	my @PAT;
	while(<$FI>) {
		chomp;
		next unless($_);
		next if(m/^\s+$/);
		print STDERR "IGNORE : " . $_ . "\n" if($OPTS{debug});
		push @PAT,$_;
	}
	close $FI;
	$TASKER->ignore(@PAT);
}

my $F_TRACE = File::Spec->catfile($CONFIGDIR,'trace');
$MYSETTING->{_TRACE} = $F_TRACE;
if(open(my $FI,'<',$F_TRACE)) {
	my @PAT;
	while(<$FI>) {
		chomp;
		next unless($_);
		next if(m/^\s+$/);
		print STDERR "TRACE  : " . $_ . "\n" if($OPTS{debug});
		push @PAT,$_;;
	}
	close $FI;
	$TASKER->trace(@PAT);
}

my $F_CONTROL = File::Spec->catfile($CONFIGDIR,'control');
sub CONTROL_INPUT {
	use MyPlace::Tasks::File qw/read_tasks/;
	my $filename = $F_CONTROL;
	return unless (-f $filename);
	my $tasks;
	if($OPTS{debug}) {
		$tasks = &read_tasks($filename,"",0,1);
	}
	else {
		$tasks = &read_tasks($filename,"",1,1);
	}
	if($tasks and @{$tasks}) {
		my $count = @$tasks;
		app_message2 "Read $count commands from CONTROL\n";
		return @{$tasks};
	}
	else {
		return;
	}
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
						my $task = shift;
						print join(" ",@_),"\n";
						return $TASK_STATUS->{DONOTHING};
					}
			)
		),
);



sub control {
	my $cmd = shift;
	return unless($cmd);
	$cmd = uc($cmd);
	app_warning("CONTROL COMMAND: $cmd\n");

	if($cmd eq 'QUIT' || $cmd eq 'EXIT') {
		exit &abort('QUIT');
	}
	if(($cmd eq 'TASK') && @_){
		app_message("Try queue task [@_]\n");
		my $task = MyPlace::Tasks::Task->new(@_);
		$TASKER->queue($task,1);
	}
}

sub abort {
	#delete $SIG{INT};
	chdir $START_DIR;
	$TASKER->abort();
	app_error "X"x10 . " " . ($_[0] || "PROGRAM KILLED!!!") . " " . "X"x10 ."\n";
	app_warning "Write configuration to $CONFIGURATION\n";
	$TASKER->exit();
	sc_to_file($CONFIGURATION,$MYSETTING);
	if($FH_LOG) {
		print $FH_LOG "[" . strtime() . "] PROGRAM ABORTED\n";
	}
}
$SIG{INT} = \&abort;

app_warning "[" . strtime() . "] Start\n";
app_warning "Directory: $START_DIR\n";


my $F_LISTENER = File::Spec->catfile($CONFIGDIR,'listener');
$MYSETTING->{_LISTENER} = $F_LISTENER;
do $F_LISTENER;

my @LISTENER = (
		@DEFAULT_LISTENERS,
		listener_init($TASKER,$TasksBuilder)
);

app_warning scalar(@LISTENER) . " listener initilized\n";
foreach(@LISTENER) {
	app_warning "Listen to namespace [" . $_->{namespace} . "]\n";
}
print STDERR "\n";

print $FH_LOG "[" . strtime() . "] PROGRAM START\n"; 
my $count =0;
while(!$TASKER->end()) {
	app_message2 "[" . strtime() . "] Waiting for event\n";
	control(@{$_}) foreach(CONTROL_INPUT());
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
		sleep 1;
		print $FH_LOG "[" . strtime() . "] TASK:" . $task->to_string . "\n";
		$count++;
		my $fired;
		foreach my $listener (@LISTENER) {
			if($listener->check($task)) {
				$fired = 1;
				$listener->fire_event($task);
				chdir $START_DIR;
			}
		}
		sleep 1;
		control(@{$_}) foreach(CONTROL_INPUT());
		$task->{status} = $TASK_STATUS->{IGNORED} unless($fired);
		$TASKER->finish($task);
		if($TASKER->{DEBUG}) {
			print $FH_LOG "[" . strtime() . "] PROGRAM DEBUG END\n"; 
			exit $TASKER->exit();
		}
		sleep 1;
	}
	elsif($TasksBuilder->more()) {
		app_message2 "[" . strtime() . "] Queuing scheduled task\n";
		$TASKER->queue($TasksBuilder->next());
	}
} 
$TASKER->exit();
sc_to_file($CONFIGURATION,$MYSETTING);
print $FH_LOG "[" . strtime() . "] PROGRAM END\n"; 
exit 0;



























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
