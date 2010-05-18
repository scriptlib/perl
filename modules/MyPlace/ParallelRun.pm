#!/usr/bin/perl -w
package MyPlace::ParallelRun;
use strict;
use warnings;
#use POSIX ":sys_wait_h";
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
my @psid;
my $running=0;
my $verbose;

sub reinit_process() {$running=0;return 0;}
sub new_process {
    my $idx = shift;
    my $id = fork();die "Unable to fork" unless(defined $id);
    if($id) {
        $psid[$idx]=$id;
        $running++;
        print STDERR "\n>>>[/",$idx+1,"/$running/$limit]PSID:$id>>>Start\n" if($verbose);
        return $running;
    }
    else {
        exit system(@_);
    }
}
sub wait_process {
    return &reinit_process() unless(@psid);
    my $id = wait();
    if($id) {
#   do {
#        $id = waitpid(-1,WNOHANG);
#        sleep 1 unless($id>0);
#        return &reinit_process() if($id == 0);
#    } until $id>0;
    for(my $idx=0;$idx<@psid;$idx++) {
        if($id == $psid[$idx]) {
            print STDERR "\n<<<[/",$idx+1,"/$running/$limit]PSID:$id<<<End\n" if($verbose);
            $running--;
            return $idx;
        }
    }
    }
    return &reinit_process(); 
}

sub para_init {
    $limit = shift;
    $verbose = shift;
    $limit = $default_limit unless($limit>=0);
    return 1;
}

sub para_isfree {
    return $running<$limit;
}

sub para_queue {
    return system(@_) if $limit<2;
    my $idx = ( $running>=$limit ? wait_process() : $running);
    return new_process($idx,@_);
}

sub para_cleanup() {
    1 while(wait_process());
}
sub DESTORY {
    print STDERR "DESTORY\n";
    para_cleanup();
}
return 1;
