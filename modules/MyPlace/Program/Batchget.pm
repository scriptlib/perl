#!/usr/bin/perl -w
# $Id$
package MyPlace::Program::Batchget;
our $VERSION = 'v0.3';
BEGIN {
    require Exporter;
    our ($VERSION,@ISA,@EXPORT,@EXPORT_OK,%EXPORT_TAGS);
    $VERSION        = 1.00;
    @ISA            = qw(Exporter);
    @EXPORT         = qw();
    @EXPORT_OK      = qw();
}
use strict;
use warnings;
use Cwd qw/getcwd/;
use MyPlace::ParallelRun;
use URI::Escape;
use MyPlace::Script::Message;
use Getopt::Long;
#use MyPlace::Usage;
use MyPlace::Program::Download;
my @OPTIONS = qw/
                help|h|? version|ver edit-me manual|man
                autoname|a cookie|b=s createdir|d ext|e=s 
                fullname|f logger|L=s maxtime|M=i maxtask|m=i
                taskname|n=s referer|r=s workdir|w=s urlhist|U
                no-clobber|nc|c numlen|i=i dl-force|dl-f
              /;

my $URL_DATABASE_FILE = 'URLS.txt';
sub load_database {
	my $self = shift;
	$self->{database} = {} unless($self->{database});
    open FI,"<",$URL_DATABASE_FILE or return;
    while(<FI>) {
        chomp;
        $self->{database}->{$_}=1;
    }
    close FI;
}
sub check_database {
	my $self = shift;
    my $url = shift;
#	return undef unless($self->{database});
	my $entry = $url;
	if(ref $url) {
		$entry = join("",@{$url});
	}
	return 1 if($self->{database}->{$entry});
	$self->{database}->{$entry} = 1;
	return undef;
}
sub save_database {
	my $self = shift;
	return 1 unless($self->{database});
	app_message("Save URLs database...\n");
    open FO,">",$URL_DATABASE_FILE or return;
    foreach (sort keys %{$self->{database}}) {
        print FO $_,"\n";
    }
    close FO;
}
sub Uniqname($) {
    my $ext =shift;
    my $max = 10000000000;
    my $result;
    do { 
        my $n1 = int (rand($max));
        my $n2 = log($max / $n1)/log(10);
        $result=$n1 . "0"x$n2 . $ext;
    } until (! -f $result);
    return $result;
}
sub GetFilename_Fullname {
	my $self = shift;
    my $result=shift;
    $result =~ s/^.*:\/\///;
    $result =~ s/[\/\?\:\\\*\&]/_/g;
    $result =~ s/&//g;
    return $result;
}

sub GetFilename_Auto {
	my $self = shift;
    my $URL=shift;
    my $num=shift;
	my $createdir = $self->{options}->{createdir};
    my $result;
    $result = $URL;
    $result =~ s/^.*:\/\///;
    $result =~ s/[\/\?\:\\\*\&]/_/g;
    $result =~ s/&//g;
    if(length($result)>=128) {
        $result = substr($result,0,127);
    }
    $result = "$num.$result" if($num);
    if($createdir) {
        my $dirname=$URL;
        $dirname =~ s/^.*:\/*[^\/]*\///;
        $dirname =~ s/\/[^\/]*//;
        $dirname .= "/" if($dirname);
        $result = $dirname . $result;    
    }
    return $result;
}
sub	GetFilename_NoAuto {
	my $self = shift;
    my $result=shift;
	my $createdir = $self->{options}->{createdir};
    if($createdir) {
        $result =~ s/^.*:\/*[^\/]*\///;
    }
    else {
        $result =~ s/^.*\///;
    }
    return $result;
}

sub set_workdir {
    my $w = shift;
    return undef unless($w);
    if(! -d $w) {
        system("mkdir","-p","--",$w) and die("$!\n");
    }
    chdir $w or die("$!\n");
    return $w;
}

sub set_reportor {
	my $self = shift;
	if(@_) {
		$self->{reportor} = shift;
		$self->{reportor_data} = shift;
	}
	return $self;
}

sub new {
	my $class = shift;
	my $self = bless {},$class;
	$self->set(@_);
	return $self;
}

sub cathash {
	my $lef = shift;
	my $rig = shift;
	return $lef unless($rig);
	return $lef unless(%$rig);
	my %res = $lef ? %$lef : ();
	foreach(keys %$rig) {
		$res{$_} = $rig->{$_} if(defined $rig->{$_});
	}
	return \%res;
}
sub set {
	my $self = shift;
	my %OPTS;
	if(@_)
	{
		Getopt::Long::Configure('no_ignore_case');
	    Getopt::Long::GetOptionsFromArray(\@_,\%OPTS,@OPTIONS);
		MyPlace::Usage::Process(\%OPTS,$VERSION);
	}
	$self->{options} = cathash($self->{options},\%OPTS);
	push @{$self->{tasks}},@_ if(@_);
	return $self;
}

sub readfile {
	my $self = shift;
	my $file = shift;
	my $GLOB = ref $file;
	my $fh;
	if($GLOB eq 'GLOB') {
		$GLOB = 1;
	}
	else {
		$GLOB = 2;
	}
	if($GLOB) {
		$fh = $file;
	}
	elsif(!open $fh,"<",$file) {
		app_error("(line " . __LINE__ . ") Error opening $file:$!\n");
		return undef;
	}
	my $count = 0;
	my @tasks = ();
	while(<$fh>) {
	    chomp;
	    s/^\s+//;
	    s/\s+$//;
		next unless($_);
		$self->add($_);
	}
	close $fh unless($GLOB);
	return $self->{tasks};
}

sub add {
	my $self = shift;
	my $task = shift;
	if(!$task) {
		app_error("Error nothing to add\n");
		return undef;
	}
	my $url = $task;
	my $name = "";
	if($task =~ /^([^\t]+)\t+(.+)$/) {
		$url = $1;
		$name = $2;
    }
    if($self->check_database($name ? "$url\t$name" : $url)) {
        app_warning("[Ignored, In DATABASE]$url\n");
		return undef;
    }
	push @{$self->{tasks}},($name ? ([$url,$name]) : $url);
	return $self->{tasks};
}

sub reset {
	my $self = shift;
	$self->{tasks} = [];
	$self->{IAMKILLED} = 0;
	return $self;
}

sub download_done {
	my $self = shift;
	my $url = shift;
	my $exitval = shift;
	if($self->{reportor}) {
		$self->{reportor}->($self->{reportor_data},$url,$exitval);
	}
}

sub execute {
	my $self = shift;
	my $OPTS = {};
	if(@_)
	{
		Getopt::Long::Configure('no_ignore_case');
	    Getopt::Long::GetOptionsFromArray(\@_,$OPTS,@OPTIONS);
		MyPlace::Usage::Process($OPTS,$VERSION);
		$OPTS = cathash($self->{options},$OPTS);
		$self->add($_) foreach(@_);
	}
	else {
		$OPTS = $self->{options};
	}
	my %OPTS = $OPTS ? %$OPTS : ();
	my $def_mul=3;
	my $createdir = $OPTS{"createdir"} ? $OPTS{"createdir"} : 0;
	my $muldown   = $OPTS{"maxtask"} ? $OPTS{"maxtask"} : $def_mul;
	my $taskname  = $OPTS{"taskname"} ? $OPTS{"taskname"} : "";
	my $autoname  = $OPTS{"autoname"} ? $OPTS{"autoname"} : 0;
	my $extname   = $OPTS{"ext"} ? $OPTS{"ext"} : "";
	my $workdir   = $OPTS{"workdir"} ? $OPTS{"workdir"} : "";
	my $refer     = $OPTS{"referer"} ? $OPTS{"referer"} : "";
	my $logger    = $OPTS{"logging"} ? $OPTS{"logging"} : "";
	my $number    = $OPTS{"numlen"} ? $OPTS{"numlen"} : "";
	my $fullname  = $OPTS{"fullname"} ? 1 : 0;
	my $urlhist   = $OPTS{'urlhist'} ? 1 : 0;
	$autoname="true" if($number);
	$taskname = "" unless($taskname);
	$muldown = 1 if( $muldown<1);
	my $prefix = $taskname ? $taskname . " " : "";
	my $index=0;
	my $count=0;
	my $PWD;
	if($workdir) {
	    set_workdir($workdir);
	}
	$PWD = getcwd;
	if($OPTS{cookie}) {
	    system("mkcookie '$OPTS{cookie}' >download.cookie");
	    $OPTS{cookie}="download.cookie";
	}
	$self->load_database() if($urlhist);
	$count = $self->{tasks} ? scalar(@{$self->{tasks}}) : 0;
	if($count < 1) {
		$self->readfile(\*STDIN);
		$count = $self->{tasks} ? scalar(@{$self->{tasks}}) : 0;
	}
	if($count < 1) {
		app_error("Nothing to do\n");
		return 0;
	}

	#app_message("Initializing...\n");
	if($count > 1 and $muldown>1) {
		para_init $muldown;
	}
	else {
		app_warning("Use single thread for downloading\n");
	}
	my $dl = new MyPlace::Program::Download (
		'--maxtime',
		$OPTS{maxtime} || '0',
		"-d",
	);
	$dl->set_reportor(\&download_done,$self);
	$dl->set("--cookie",$OPTS{cookie}) if($OPTS{cookie});
	my %QUEUE;
	app_message("Queue $count download tasks\n") if($count>1);
	while (@{$self->{tasks}}) {
		if($self->{IAMKILLED}) {
			last;
		}
		local $_ = shift @{$self->{tasks}};
		$index++;
		my $msghd = $count > 1 ? "${prefix}\[$index/$count]" : "";
		next unless($_);
		my $url;
		my $filename ;
		if(ref $_) {
			$url = $_->[0];
			$filename = $_->[1];
		}
		else {
			$url = $_;
			$filename = "";
		}
#		app_message($msghd,"Queuing $url...\n");
#		app_message("  => $filename\n") if($filename);
	    if($url =~ m/^#BATCHGET:chdir:(.+)$/) {
	        my $w = $1;
	        $w =~ s/[:\?\*]+//g;
	        if($w) {
				app_message($msghd,"Program action [chdir] to $1\n");
	            chdir $PWD or die("$!\n");
	            set_workdir($w);
	        }
	    }
		elsif($QUEUE{$_}) {
			app_warning($msghd,"Duplicated task. [Ignored]\n");
		}
		else {
			if(!$filename) {
				my $stridx = "0" x (length($count)-length($index)+1) . $index if($number);
				$filename = $fullname ? $self->GetFilename_Fullname($url) 
					: $autoname ? $self->GetFilename_Auto($url,$stridx) 
					: $self->GetFilename_NoAuto($url);
			}
			if($OPTS{"no-clobber"} and -f $filename) {
				app_warning($msghd,"$url\t[Ignored, TARGET EXISTS]\n");
	            next;
			}
			if($logger) {system($logger,$filename,$url);}

			my @args = (
				'--saveas'=>$filename,
				'-n'=>$msghd,
				'-r'=>$OPTS{'referer'} || $url,
				'--url'=>$url,
				$OPTS{'dl-force'} ? '-f' : (),
			);
			if($count > 1 and $muldown>1) {
				para_queue(\&download,$self,$dl,@args);
			}
			else {
				$self->download($dl,@args);
			}
#			my $exitval = $dl->execute(
#				'-saveas'=>$filename,
#				'-n'=>$msghd,
#				'-r'=>$OPTS{'referer'} || $url,
#				'-url'=>$url
#			);
#			if($exitval == 2) {
#				app_warning("Child process killed\n");
#				return 2;
#			}
	    }
	}
	para_cleanup() if($count > 1 and $muldown>1);
	chdir $PWD;
	$self->save_database() if($urlhist);
	if($self->{IAMKILLED}) {
		app_warning("I am killed!\n");
		$self->{IAMKILLED} = 0;
		return 2;
	}
	return 0;
}

sub download {
	my $self = shift;
	my $dl = shift;
	my $exitval = $dl->execute(@_);
	if($exitval == 2) {
		$self->{IAMKILLED} = 1;
	}
	return $exitval;
}

return 1 if caller;
my $PROGRAM = new(__PACKAGE__);
exit $PROGRAM->execute(@ARGV);



__END__

=pod

=head1  NAME

batchget - A batch mode downloader

=head1  SYNOPSIS

batchget [options] ...

cat url.lst | batchget

cat url.lst | batchget -a -d 

=head1  OPTIONS

=over 12

=item B<-a,--autoname>

Use indexing of URLs as output filename 

=item B<-b,--cookie>

Use cookie jar

=item B<-c,--nc,--no-clobber>

No clobber when target exists.

=item B<-d,--createdir>

Create directories

=item B<-e,--ext>

Extension name for autonaming

=item B<-f,--fullname>

Use URL as output filename

=item B<-i,--numlen>

Number length for index filename

=item B<-M,--maxtime>

Max time for a single download process

=item B<-m,--maxtask>

Max number of simulatanous downloading task

=item B<-n,--taskname>

Task name

=item B<-r,--referer>

Global referer URL

=item B<-w,--workdir>

Global working directory

=item B<-U,--urlhist>

Use URL downloading history databasa

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

A downloader which can download multiple urls at the same time and/or in queue.

=head1  CHANGELOG

    2007-10-28  xiaoranzzz  <xiaoranzzz@myplace.hell>
    
        * file created, version 0.1

    2010-08-03  xiaoranzzz  <xiaoranzzz@myplace.hell>
        
        * update to version 0.2

=head1  AUTHOR

xiaoranzzz <xiaoranzzz@myplace.hell>

=cut


# vim:filetype=perl

