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
	no-git|ng
	no-pull|np
	debug|D
	no-push
	runonce|run
	no-download|nd
	include|I:s
	exclude|X:s
	no-saveurl|ns
/;
my %OPTS;
my $USE_LAST_CONFIG = 1;
if(@ARGV)
{
    require Getopt::Long;
    if(!Getopt::Long::GetOptions(\%OPTS,@OPTIONS)) {
		die("Error, invalid option specified\n");
	}
	$USE_LAST_CONFIG = undef;
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
our $MYSETTING = $OPTS{runonce} ? {} :  sc_from_file($CONFIGURATION);

my @CONFIG_KEYS = qw/sleep/;
my @CMDLINE_OPTS = qw/no-pull no-push no-download no-git include exclude no-saveurl/;
my @OPTS_KEYS = ($USE_LAST_CONFIG ? (@CONFIG_KEYS,@CMDLINE_OPTS) : @CONFIG_KEYS);
foreach (@OPTS_KEYS) {
	$OPTS{$_} = $MYSETTING->{"options.$_"} if(!defined $OPTS{$_});
}
foreach(@CONFIG_KEYS,@CMDLINE_OPTS) {
	if(defined $OPTS{$_}) {
		$MYSETTING->{"options.$_"} = $OPTS{$_};
	}
	else {
		delete $MYSETTING->{"options.$_"};
	}
}


$MYSETTING->{_DIR} = $CONFIGDIR;
print STDERR "CONFIG : $CONFIGDIR\n" if($OPTS{debug});

my $TASKER;

######DISABLE GIT
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
foreach(@CONFIG_KEYS,@CMDLINE_OPTS) {
	if(defined $OPTS{$_}) {
		$TASKER->{options}->{$_} = $OPTS{$_};
	}
	else {
		delete $TASKER->{options}->{$_};
	}
}
$TASKER->{DEBUG} = 1 if($OPTS{debug});
$TASKER->runonce(@ARGV) if($OPTS{runonce});

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



my $START_DIR = getcwd;
my $TasksBuilder = MyPlace::Tasks::Builder->new(level=>20);
my $TasksBuilder2 = MyPlace::Tasks::Builder->new(level=>10);
my $TasksBuilder3 = MyPlace::Tasks::Builder->new(level=>0);
my @DEFAULT_LISTENERS = (
		MyPlace::Tasks::Listener->new('dump', 
			MyPlace::Tasks::Worker->new(
					name=>'dump',
					routine=>sub{
						my $self = shift;
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
						my $self = shift;
						my $task = shift;
						print join(" ",@_),"\n";
						return $TASK_STATUS->{DONOTHING};
					}
			)
		),
		MyPlace::Tasks::Listener->new('mdown',
			MyPlace::Tasks::Worker->new(
					name=>'mdown',
					'no-download'=>$OPTS{'no-download'},
					routine=>sub{
						my $self = shift;
						if($self->{'no-download'}) {
							app_message "NO-DOWNLOAD mode, do nothing\n";
							return $TASK_STATUS->{DONOTHING};
						}
						my $task = shift;
						my @prog = ('mdown',@_);
						print STDERR join(" ",@_),"\n";
						if(system(@prog) == 0) {
							return $TASK_STATUS->{FINISHED};
						}
						else {
							return $TASK_STATUS->{ERROR};
						}
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
	if(!$OPTS{runonce}) {
		app_warning "Write configuration to $CONFIGURATION\n";
	#$TASKER->exit();
		sc_to_file($CONFIGURATION,$MYSETTING);
	}
	if($FH_LOG) {
		print $FH_LOG "[" . strtime() . "] PROGRAM ABORTED\n";
	}
	exit 1;
}
$SIG{INT} = \&abort;

app_warning "[" . strtime() . "] Start\n";
app_warning "Directory: $START_DIR\n";

my @LISTENER = @DEFAULT_LISTENERS;
sub find_worker {
	my $namespace = shift;
	foreach my $listener (@LISTENER) {
		if($listener->check({'namespace'=>$namespace})) {
			return $listener->{worker};
		}
	}
}

my $F_LISTENER = File::Spec->catfile($CONFIGDIR,'listener');
$MYSETTING->{_LISTENER} = $F_LISTENER;

if(-f $F_LISTENER) {
	do $F_LISTENER;
	if($@) {
		app_error "Error loading $F_LISTENER:\n";
		die($@,"\n");
	}
	else {
		push @LISTENER,listener_init(\%OPTS,$TASKER,$TasksBuilder,$TasksBuilder2,$TasksBuilder3);
	}
}

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
#		if($task->to_string() =~ m/vlook.cn/) {
#			app_warning "SKIP VLOOK.CN TASKS NOW!!!\n";
#			next;
#		}
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
				my $r = $listener->fire_event($task);
				chdir $START_DIR;
				if($r and ( $r  == $TASK_STATUS->{FATALERROR})) {
					exit abort("FATALERROR");
				}
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
		if($count and !($count % 10)) {
			#$TASKER->save();
			app_warning "Write configuration to $CONFIGURATION\n";
			sc_to_file($CONFIGURATION,$MYSETTING);
		}
		sleep 1;
	}
	elsif($OPTS{runonce}) {
		last;
	}
	elsif($TasksBuilder->more()) {
		app_message2 "[" . strtime() . "] Queuing scheduled task\n";
		$TASKER->queue($TasksBuilder->{level},$TasksBuilder->next());
	}
	elsif($TasksBuilder2->more()) {
		app_message2 "[" . strtime() . "] Queuing scheduled task\n";
		$TASKER->queue($TasksBuilder2->{level},$TasksBuilder2->next());
	}
	elsif($TasksBuilder3->more()) {
		app_message2 "[" . strtime() . "] Queuing scheduled task\n";
		$TASKER->queue($TasksBuilder3->{level},$TasksBuilder3->next());
	}
} 
if(!$OPTS{runonce}) {
	$TASKER->exit();
	sc_to_file($CONFIGURATION,$MYSETTING);
}
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
