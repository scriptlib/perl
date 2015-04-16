#!/usr/bin/perl -w
# $Id$
use strict;
our $VERSION = 'v0.1';
my @OPTIONS = qw/
	help|h|? 
	manual|man
	duplicated|dup
	no-cover|nc
	junction
	all
	no-junction
	clean
	clips
	trash
	reposter
	retry
/;
my %OPTS;
if(@ARGV)
{
    require Getopt::Long;
    Getopt::Long::GetOptions(\%OPTS,@OPTIONS);
}
else {
	$OPTS{'help'} = 1;
}
if($OPTS{'help'} or $OPTS{'manual'}) {
	require Pod::Usage;
	Pod::Usage::pod2usage(-exitval=>"NOEXIT",-verbose=>1);
}

sub run {
	print STDERR "\t@_\n";
	return (system(@_) == 0);
	return 1;
}

my $cmd = shift;
my $CMD = uc($cmd) if($cmd);
foreach(@ARGV) {
	s/\/+$//;
}
my %COMMANDS = (
	List=>'List videos in specified directory',
	Move=>'Move specified directory',
	Clean=>'Delete videos in specified directory',
	Close=>'Clean, and move specified directory',
	Update=>'Update profile',
	Download=>'Run downloader in directories',
);
if(!$CMD) {
	print STDERR "Commands:\n";
	print STDERR "    $_\n                $COMMANDS{$_}\n" foreach(keys %COMMANDS);
	exit 0;
}
elsif($CMD eq 'LIST') {
	exit Babes::List::process(\%OPTS,@ARGV);
}
elsif($CMD eq 'MOVE') {
	#require Babes::Move;
	exit Babes::Move::process(\%OPTS,@ARGV);
}
elsif($CMD eq 'CLEAN') {
	exit Babes::Clean::process(\%OPTS,@ARGV);
}
elsif($CMD eq 'UPDATE') {
	exit Babes::Update::process(\%OPTS,@ARGV);
}
elsif($CMD eq 'CLOSE') {
	exit Babes::Close::process(\%OPTS,@ARGV);
}
elsif($CMD eq 'DOWNLOAD') {
	exit Babes::Download::process(\%OPTS,@ARGV);
}
else {
	die("Command not found: $cmd\n");
}


1;
#######################################################################
package Babes::Move;
use File::Spec::Functions qw/catfile catdir/;
use strict;

our $MOVE_TRASH_DIR = '#Trash';
our $MOVE_CLIPS_DIR = '#Clips';
our $MOVE_REPOSTER_DIR = '#Reposter';
sub run {
	goto &main::run;
}

sub move_to {
	my $OPTS = shift;
	my $dstd = shift;
	my %clips;
	my $exit;
	foreach my $srcd (@_) {
#		print STDERR $srcd,"\n";
		foreach my $file (glob("$srcd/*/*/*.*")) {
#			print STDERR $file,"\n";
			if($file =~ m/([^\/]+)\/[^\/]+\/([^\/]+)\/([^\/]+\.(?:jpg|mov|flv|mp4|f4v|mpeg|png|gif))$/) {
				$clips{$file} = "$1_$2_$3";
			}
		}
	}

	if($OPTS->{clips}) {
		foreach my $src (keys %clips) {
			my $dst = catfile($dstd,$clips{$src});
			$exit = run('mv','-v','--',$src,$dst);
		}
		$dstd = $MOVE_TRASH_DIR;
	}
	elsif($OPTS->{trash}) {
		foreach my $src (keys %clips) {
			$exit = run('rm','-v','--',$src);
		}
	}

	foreach(@_) {$exit = run('mv','-v','-t',$dstd,'--',$_)};

	return ($exit == 0);
}

sub process {
	my $OPTS = shift;
our $MOVE_TRASH_DIR = '#Trash';
our $MOVE_CLIPS_DIR = '#Clips';
our $MOVE_REPOSTER_DIR = '#Reposter';

	if(!@_) {
		die("Usage: \n" .
			"  $0 move [options] target_directory source_directory ...\n" .
			"  $0 move [--clips|--reposter|--trash] directories ...\n"
		);
	}
	if($OPTS->{clips}) {
		return move_to($OPTS,$MOVE_CLIPS_DIR,@_);
	}
	elsif($OPTS->{reposter}) {
		return move_to($OPTS,$MOVE_REPOSTER_DIR,@_);
	}
	elsif($OPTS->{trash}) {
		return move_to($OPTS,$MOVE_TRASH_DIR,@_);
	}

	my $DST = shift;
	my $exit = 0;
	if(!@_) {
		die("Usage: \n" .
			"  $0 move [options] target_directory source_directory ...\n" .
			"  $0 move [--clips|--reposter|--trash] directories ...\n"
		);
	}
	foreach my $SRC (@_) {
		print STDERR "[$SRC] Moving to $DST/\n";
		if(-l $SRC) {
			print STDERR "	Ignored, [$SRC] is a symbol link\n";
			next;
		}
		elsif(! -d $SRC) {
			print STDERR "	Ignored, [$SRC] is not a directory\n";
			next;
		}
		elsif(! -d $DST) {
			print STDERR "	Error, [$DST] directory not exist\n";
			next;
		}
		elsif(run("mv","-v","-t",$DST,"--",$SRC)) {
			print STDERR "\t [OK]\n";
			if(!$OPTS->{'no-junction'}) {
				my $target=`cygpath -w "$DST/$SRC"`;
				chomp($target);
	
				my $junction=$SRC;
				
				if(run("junction.exe",$junction,$target)) {
					print STDERR "\t [OK]\n";
					$exit = 0;
				}
				else {
					print STDERR "\t [FAILED]\n";
					$exit = 1;
				}
			}
			$exit = 0;
		}
		else {
			print STDERR "\t [FAILED]\n";
			$exit = 1;
		}
	}
	return $exit;
}

1;

#######################################################################

package Babes::List;

use strict;
use warnings;
use File::Spec::Functions qw/catfile catdir/;
use Cwd qw/getcwd/;
$SIG{INT} = sub {
	die();
};
sub run {
	goto &main::run;
}
sub list_dup_site {
	my $site = shift;
	my $dir = shift;
	my $name = shift;
	my $processed;
	my $cwd_kept = getcwd;
	foreach(glob(catfile($dir,'*'))) {
		next if(m/^\./);
		next unless(-d $_);
		list_dup_file($_);
		chdir $cwd_kept;
		$processed = 1;
	}
	if(!$processed) {
		print STDERR "[$site] No ID found for $name\n";
	}
}
sub list_dup_dir {
	my $dir = shift;
	my $processed;
	foreach(glob($dir . '/*')) {
		next unless(-d $_);
		if(m/\/(vlook\.cn|weipai\.cn)\/?$/) {
			list_dup_site($1,$_,$dir);
			$processed = 1;
		}
	}
	if(!$processed) {
		print STDERR "Error no sites ID found for $dir\n";
	}
}

sub list_dup_file {
	my $dir = shift;
	my @files;
	my %exps;
	my %dups;
	chdir $dir;
	foreach (glob("*.*")) {
		push @files,$_;
		next if(m/\.jpg/);
		if(m/^(\d{8})\d\d_(.+)\.[^\.]+$/) {
			$exps{$1 . '\d*_' . $2 . '\[\d+[^\[\]]+\]\.'} = $_;
		}
	}
	foreach(@files){
		foreach my $exp(keys %exps) {
			if(m/$exp/) {
				$dups{$exps{$exp}} =[] unless($dups{$exps{$exp}});
				push @{$dups{$exps{$exp}}},$_;
			}
		}
	}
	foreach my $kept (keys %dups) {
		print STDERR $kept,"\n";
		foreach my $dup(@{$dups{$kept}}) {
			print STDERR "  [X]$dup\n"; 
		}
	}
	print STDERR "\n" . "X"x80 . "\n";
	foreach my $kept (keys %dups) {
		foreach my $dup(@{$dups{$kept}}) {
			print "$dir/$dup\n"; 
		}
	}
	return %dups;
}

sub get_videos {
	my $dir = shift;
	my $msg = shift;
	my %videos;
	my %images;
	print STDERR "Processing $dir  " if($msg);
	my @subdirs;
	my @result;
	foreach (glob("$dir/*")) {
		next if(m/\.$/);
		if(-d $_) {
			push @subdirs,$_;
			next;
		}
		if(m/(.+)\.(?:jpg|png|jpeg|gif)$/) {
			push @result,$_;
		}
		elsif(m/(.+)\.(?:mov|mp4|flv|f4v)$/) {
			push @result,$_;
		}
	}
	foreach my $video (keys %videos) {
#		print STDERR $video,"\n";
		my $basename = $videos{$video};
		push @result,$video unless($images{$basename});
	}
	print STDERR "[" . scalar(@result) . " file(s)]\n" if($msg);
	foreach(@subdirs) {
		push @result,get_videos($_,$msg);
	}
	return @result;
}
sub get_no_cover {
	my $dir = shift;
	my @files = get_videos($dir,0);
	my %images;
	my %videos;
	my @result;
	foreach(@files) {
		if(m/(.+)\.(?:jpg|png|jpeg|gif)$/) {
			my $basename = $1;
			$basename =~ s/\.3in1$//;
			$basename =~ s/\.mov$//;
			$basename =~ s/\.\d$//;
			$images{$basename} = 1;
		}
		elsif(m/(.+)\.(?:mov|mp4|flv|f4v)$/) {
			$videos{$_} = $1;
		}
	}
	foreach my $video (keys %videos) {
		my $basename = $videos{$video};
		push @result,$video unless($images{$basename});
	}
	return @result;
}

sub list_no_cover {
	my $dir = shift;
	my @result = get_no_cover($dir);
	print $_,"\n" foreach(@result);
	return 0;
}

sub list_videos {
	my $dir = shift;
	print $_,"\n" foreach(get_videos($dir,1));
	return 0;
}



sub process {
	my $OPTS = shift;
	if($OPTS->{duplicated}) {
		list_dup_dir($_) foreach(@_);
	}
	elsif($OPTS->{'no-cover'}) {
		list_no_cover($_) foreach(@_);
	}
	else {
		list_videos($_) foreach(@_);
	}
}

1;

#######################################################################
package Babes::Update;
use strict;
use warnings;
use File::Spec::Functions qw/catfile catdir/;
use Cwd qw/getcwd/;

sub process_weipai {
	my $OPTS = shift;
	my $dir = shift;
	my $name = shift;
#	my $cwd = getcwd;
#	if(!chdir $dir) {
#		print STDERR "Error entering directory $dir:$!\n";
#		return 1;
#	}
	my $processed;
	foreach(glob(catfile($dir,'*'))) {
		next if(m/^\./);
		next unless(-d $_);
		my $id = $_;
		$id =~ s/.*[\/\\]//g;
		print STDERR "[$name] Saving profile ($id)\n";
		if((!$OPTS->{force}) and -f "$id.txt" and -f "$id.jpg") {
			print STDERR "	Ignored, profile files exist\n";
		}
		else {
			system("weipai","save-profile",$id);
		}
		$processed = 1;
	}
#	chdir($cwd);
	if(!$processed) {
		print STDERR "	Error, No weipai ID found for $name\n";
	}
}
sub process_dir {
	my $OPTS = shift;
	my $dir = shift;
	my $cwd = getcwd;
	if(!chdir $dir) {
		print STDERR "Error entering directory $dir:$!\n";
		return 1;
	}
	my $processed;
	foreach(glob('*')) {
		if(m/^weipai\.cn$/) {
			process_weipai($OPTS,$_,$dir);
			$processed = 1;
		}
	}
	chdir $cwd;
	if(!$processed) {
		print STDERR "Error not profile found for $dir\n";
	}
}

sub process {
	my $OPTS = shift;
	foreach(@_) {
		if(-d $_) {
#			print STDERR "\nProcessing $_\n";
			process_dir($OPTS,$_);
		}
		else {
			#print STDERR "Error not a directory:$_\n";
		}
	}
}
1;

#######################################################################
package Babes::Clean;
sub process {
	my $OPTS = shift;
	foreach(@_) {
		print STDERR "Processing [$_] ... ";
		my @result;
		if($OPTS->{duplicated}) {
			@result = Babes::List::get_duplicated($_,1);
		}
		elsif($OPTS->{all}) {
			@result = Babes::List::get_videos($_);
		}
		else {
			@result = Babes::List::get_no_cover($_);
		}
		print STDERR " >Get " . scalar(@result) . " result\n";
		&main::run("rm","-v","--",$_) foreach(@result);
	}
	return 0;
}
1;

#######################################################################
package Babes::Close;
sub process {
	my $OPTS = shift;
	my $DST;
	if($OPTS->{trash} or $OPTS->{reposter} or $OPTS{clips}) {
		delete $OPTS{junction};
	}
	else {
		$OPTS{junction} = 1;
		$DST = shift;
	}

	if(!@_) {
		die("Usage: $0 close [options] target_directory source_directory\n");
	}
	
	foreach my $SRC (@_) {
		Babes::Clean::process($OPTS,$SRC) if($OPTS{'clean'});
		Babes::Update::process($OPTS,$SRC);
		if($DST) {
			Babes::Move::process($OPTS,$DST,$SRC);
		}
		else {
			Babes::Move::process($OPTS,$SRC);
		}
	}
}
1;
#######################################################################

package Babes::Download;
use strict;
use warnings;

sub process {
	my $OPTS = shift;
	if(!@_) {
		die("Usage:\n  $0 download [options] directories...\n");
	}
	my @prog = ('mdown','--recursive');
	push @prog,'--retry' if($OPTS->{retry});
	my $exit = 0;
	foreach(@_) {
		$exit = &main::run(@prog,'-d',$_);
	}
	return $exit;
}
1;
#######################################################################


__END__

=pod

=head1  NAME

babes - PERL script

=head1  SYNOPSIS

babes <command> [options] ...

=head1  OPTIONS

=over 12

=item B<--no-cover>,B<--nc>

List vidoes without cover image

=item B<--junction>

Create junction for directory

=item B<--duplicated>,B<--dup>

List video files duplicated others

=item B<--version>

Print version infomation.

=item B<-h>,B<--help>

Print a brief help message and exits.

=back

=head1  DESCRIPTION

___DESC___

=head1  CHANGELOG

    2015-02-23 01:45  xiaoranzzz  <xiaoranzzz@MyPlace>
        
        * file created.

=head1  AUTHOR

xiaoranzzz <xiaoranzzz@MyPlace>

=cut

#       vim:filetype=perl
