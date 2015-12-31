#!/usr/bin/perl -w
package MyPlace::Tasks::Worker::SearchTorrents;
use strict;
use warnings;
use MyPlace::Tasks::Task qw/$TASK_STATUS/;
use MyPlace::Script::Message;
use File::Spec::Functions qw/catfile catdir/;
use MyPlace::Classify qw/read_rules/;
use MyPlace::Tasks::Utils qw/strtime/;
BEGIN {
    require Exporter;
    our ($VERSION,@ISA,@EXPORT,@EXPORT_OK,%EXPORT_TAGS);
    $VERSION        = 1.00;
    @ISA            = qw(Exporter);
    @EXPORT         = qw();
    @EXPORT_OK      = qw(read_keywords new_search);
}
use parent 'MyPlace::Tasks::Worker';

sub NEW_TASK  {
		my $task = shift;
		my $newtask = new MyPlace::Tasks::Task(@_);
		foreach(qw/target_dir source_dir workdir options level/) {
			$newtask->{$_} = $task->{$_};
		}	
		return $newtask;
}

sub new {
	my $class = shift;
	my $self = $class->SUPER::new(name=>'search_torrents',@_);
	$self->{routine} = \&work;
	return $self;
}


sub score {
	my $self = shift;
	my $board = shift;
	my $id = shift;
	my $point = shift;
	return unless(defined $point);
	my @rows;
	if(open FI,"<",$board) {
		@rows = <FI>;
		close FI;
	}
	else {
		@rows = ();
	}
	my $score;
	my $count;
	if(!open FO,">",$board) {
		print STDERR "Error opening file \"$board\":$!\n";
		return;
	}
	while(@rows) {
		my $row = shift(@rows);
		if(defined $score) {
			print FO $row;
			next;
		}
		my ($r_id,$r_count,$r_point,@datas) = split(/\s*\t\s*/,$row);
		if(!$r_id) {
			print FO $row;
			next;
		}
		if($r_id eq $id) {
			$score = int($r_point + $point);
			$count = $r_count ? $r_count + 1 : 1;
			last;
		}
		else {
			print FO $row;
		}
	}
	if(!defined $score) {
		$score = $point;
		$count = 1;
	}
	print FO join("\t",$id,$count,$score,@_),"\n";
	print FO @rows if(@rows);
	close FO;
	print STDERR "SCORE: $id => $count/$score\n";
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


sub read_keywords {
	my $fr = shift;
	my $rules = read_rules($fr);
	my @queries;

	my $count = 0;
	foreach(@$rules) {
		push @queries,$_->{name};
		$count++;
	}
	print STDERR "\tOK: $count keywords read\n";
	return @queries;
}

sub prog_search_torrents {
	my @queries;
	my @options;
	my $noopt;
	my %OPTS;
	my $rulefile = shift;
	foreach(@_) {
		my $l = lc($_);
		if($noopt) {
			push @queries,$_;
		}
		elsif($_ eq '--') {
			$noopt = 1;
		}
		elsif($l eq '--new') {
			$OPTS{new} = 1;
		}
		elsif($l eq '--download') {
			$OPTS{download} = 1;
		}
		elsif($l eq '--nsfw') {
			$OPTS{group} = 'NSFW';
		}
		elsif($l eq '--safe') {
			$OPTS{group} = 'SAFE';
		}
		elsif($l eq '-d') {
			$OPTS{download} = 1;
		}
		elsif(substr($_,0,1) eq '-') {
			push @options,$_;
		}
		else {
			push @queries,$_;
		}
	}
	my @PROG = qw{
		classify
		--action keyword
	};
	push @PROG,'--rule',$rulefile;

	my @prefix = ('search_torrents');
	push @prefix,'-d' if($OPTS{download});
	push @prefix,'-g',$OPTS{group} if($OPTS{group});

	if($OPTS{new}) {
		my @keywords = read_keywords($rulefile);
		my $count = 0;
		foreach(@keywords) {
			my $name = $_;
			$name =~ s/^<+//;
			if(!-d $name) {
				print STDERR "\t",$name;
				push @queries,$name;
				$count++;	
			}
		}
		if(@queries) {
			print STDERR "\n";
			print STDERR "\tOK: $count new entries read\n";
		}
		else {
			print STDERR "\n\tError: $!\n";
			return $TASK_STATUS->{DONOTHING};
		}
	}

	push @prefix,@options if(@options);
	push @PROG,"--prefix","@prefix";
	push @PROG,@queries;

	my @logtext; 

	push @logtext,&strtime(),"\n","\tKEYWORD: ",join(", ",@queries),"\n";
	push @logtext,"\tPROGRAM: ",join(" ",@prefix),"\n";

	print STDERR @logtext;
	open FO,">>","search_torrents.log";
	print FO @logtext;
	close FO;
	if(system(@PROG) == 0) {
		return 0;
	}
	else {
		return $TASK_STATUS->{ERROR};
	}
}
	sub new_search {
		my $rulename = shift;
		my %props = @_;
		my $filename;

		if($rulename =~ m/^([^:]+):(.+)$/) {
			$rulename = $1;
			$filename = $2;
		}
		else {
			$filename = $rulename;
		}

		my %pool =  (
			prefix=>['search_torrents',"$rulename:$filename"],
			data=>sub {
				my @follows = ();
				return read_keywords($filename . ".rule");
			},
			%props,
		);

		use Data::Dumper;print STDERR Data::Dumper->Dump([\%pool],['$pool_' . $rulename]),"\n";
		return %pool;
	}

sub work {
	my $self = shift;
	my $task = shift;
	my $rulename = shift;
	my $rulefile = "../$rulename.rule";
	if($rulename =~ m/^([^:]+):(.+)$/) {
		$rulename = $1;
		$rulefile = "../$2.rule";
	}
	my $WD = $self->{target_dir} || $task->{target_dir} || $rulename;
	my $ERROR_WD = $self->set_workdir($task,$WD);
	return $ERROR_WD if($ERROR_WD);
	if(! -f $rulefile) {
		return $self->error($task,"File not accessible: $rulefile");
	}
	#return $self->dump_info($task);
	my %WORKER_OPTS = ($self->{options} ? %{$self->{options}} : ());
	my %TASK_OPTS = ($task->{options} ? %{$task->{options}} : ());
	my @opts;
	my %OPTS;
	foreach ('no-download','engine','nsfw','safe') {
		$OPTS{$_} = defined $TASK_OPTS{$_} ? $TASK_OPTS{$_} : $WORKER_OPTS{$_};
	}
	push @opts,'-d' unless($OPTS{'no-download'});
	push @opts,'-e',$OPTS{engine} if($OPTS{'engine'});
	if($OPTS{'nsfw'}) {
		push @opts,'--nsfw';
	}
	elsif($OPTS{'safe'}) {
		push @opts,'--safe';
	}
	my $exit =  prog_search_torrents($rulefile,@opts,@_);
	if($exit == 0) {
		return $TASK_STATUS->{FINISHED},'OK';
	}
	else {
		return $exit,'Failed';
	}
}

sub execute_task {
	my $self = shift;
	my $task = shift;
	chdir $self->{KEPTWD} if($self->{KEPTWD});
	app_message " * " . ($task->{title} || $task->to_string()) . "\n";
	my ($r,$s) = $self->process($task,$task->content());
	if($task->{summary}) {
		print STDERR $task->{summary},"\n";
	}
	my @NEWTASKS;
	if($r == $TASK_STATUS->{NEWTASKS}) {
		@NEWTASKS = @{$s} if($s);
	}
	if($task->tasks) {
		push @NEWTASKS,$task->tasks;
	}
	if(@NEWTASKS) {
		foreach my $ts (@NEWTASKS) {
			my $level = shift(@$ts);
			next if(!defined $level);
			if($level =~ m/^\s*(\d+)\s*$/) {
			$level = $1;
			}
			else {
				unshift @$ts,$level;
				$level = undef;
			}
			my $tss = $ts->[0];
			if(!$tss) {
			}
			elsif(ref $tss eq 'ARRAY') {
				foreach(@$tss) {
					($r,$s) = $self->execute_task($_) if($_);
				}
			}
			else {
				($r,$s) = $self->execute_task($tss)
			}
		}
	}
	return $r;
}

sub execute {
	my $self = shift;
	my $OPTS = shift;
	my $task = MyPlace::Tasks::Task->new('search_torrents',@_);
	$task->{options} = $OPTS;
	use Cwd qw/getcwd/;
	$self->{KEPTWD} = getcwd;
	return $self->execute_task($task);
}

1;

package MyPlace::Tasks::Worker::SearchTorrents::Program;
use parent 'MyPlace::Program';
our $VERSION = "1.0";
sub OPTIONS {qw/
	help|h
	directory|d=s
	no-download|nd
	engine|e=s
/;}
sub USAGE {
	my $appname = $0;
	$appname =~ s/^.*[\/\\]//;
	print STDERR "$appname v$VERSION - Torrents Searcher\n\n";
	print STDERR "Usage: $appname [--directory <path>] keyword|type queries...\n\n";
	print STDERR "\t$appname avstars Julia\n";
	print STDERR "\t$appname tags #MILF\n";
	print STDERR "Copyright, 2015-, Eotect\n";
	return 0;
}
sub MAIN {
	my $self = shift;
	my $OPTS = shift;
	my $APP = new MyPlace::Tasks::Worker::SearchTorrents;
	$self->{options} = {%$OPTS};
	$APP->{options} = {%$OPTS};
	$APP->{source_dir} = "search_torrents";
	if($OPTS->{directory}) {
		$APP->{target_dir} = $OPTS->{directory};
	}
	exit $APP->execute($OPTS,@_);
}
return 1 if(caller);
my $APP = new MyPlace::Tasks::Worker::SearchTorrents::Program;
exit $APP->execute(@ARGV);

1;

