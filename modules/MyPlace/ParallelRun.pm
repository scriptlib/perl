#!/usr/bin/perl -w
package MyPlace::ParallelRun;
use strict;
use warnings;
use POSIX ":sys_wait_h";
BEGIN {
    use Exporter ();
    our ($VERSION,@ISA,@EXPORT,@EXPORT_OK,%EXPORT_TAGS);
    $VERSION        = 1.00;
    @ISA            = qw(Exporter);
    @EXPORT         = qw(&para_isfree &para_init &para_queue &para_cleanup);
    @EXPORT_OK      = qw();
}

my $default_limit = 3;
my $limit;
my %psid;
my $running=0;
my $verbose;

sub reinit_process() {$running=0;return 0;}
sub new_process {
#    my $idx = shift;
    my $id = fork();die "Unable to fork" unless(defined $id);
    if($id) {
        $psid{$id}=1;
        $running++;
        print STDERR "\n>>>[Runing:$running/Limit:$limit]PSID:$id>>>Start\n" if($verbose);
        return $running;
    }
    else {
        exit &invoke(@_);
    }
}

sub para_isfree {
    if($running<$limit) {
        return 1;
    }
    &para_wait;
    return $running<$limit;
}

sub para_wait {
    my $pid = waitpid(-1,WNOHANG);
    if($pid>0) {
        $running--;
        print STDERR "\n>>>[Runing:$running/Limit:$limit]PSID:$pid>>>End\n" if($verbose);
    }
    return $pid;
}


sub wait_process {
    return &reinit_process() unless($running>0 and %psid);
    my $id=-1;
    until($id>0){
        $id = &para_wait;
        sleep 1;
    };
    return 1;
}

sub para_init {
    $limit = shift;
    $verbose = shift;
    $limit = $default_limit unless($limit>=0);
    return 1;
}

sub invoke {
	my $program = shift;
	my @args = @_;
	my $type = ref $program;
	if($type eq 'CODE') {
		return &$program(@args);
	}
	else {
		return system($program,@args) == 0;
	}
}

sub para_queue {
    return &invoke(@_) if $limit<2;
    if($running>=$limit) {
        wait_process();
    }
    return new_process(@_);
}

sub para_cleanup() {
    1 while(wait_process());
}
sub DESTORY {
    print STDERR "DESTORY\n";
    para_cleanup();
}
return 1;
