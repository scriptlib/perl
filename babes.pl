#!/usr/bin/perl -w
package Babes;
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
	reverse
	revert
	move
	images
	videos
	include
	exclude
	into=s
	follow
	unfollow
	enable
	disable
/;
sub strtime {
	my $time =  shift(@_) || time();
	my $style = shift;
	my $sep1 = shift(@_); 
	my $sep2 = shift(@_);
	my $sep3 = shift(@_);
	$sep1 = "/" unless(defined $sep1); #seperator for date (year/month/day)
	$sep2 = ":" unless(defined $sep2); #seperator for time (hour::minute::second)
	$sep3 = " " unless(defined $sep3); #seperator seperated date and time
	my @r = localtime($time);
	my $year   = $r[5] + 1900;
	my $month  = $r[4]  > 9  ? ($r[4] + 1) : '0' . ($r[4]+1);
	my $day    = $r[3] > 9 ? $r[3] : '0' . $r[3];
	my $hour   = $r[2] > 9 ? $r[2] : '0' . $r[2];
	my $minute = $r[1] > 9 ? $r[1] : '0' . $r[1];
	my $second = $r[0] > 9 ? $r[0] : '0' . $r[0];
	my $clock = "$hour$sep2$minute$sep2$second";
	if((!$style) or ($style == 4)) {
		return "$year$sep1$month$sep1$day$sep3$clock";
	}
	elsif($style == 3) {
		return "$month$sep1$day$sep3$clock";
	}
	elsif($style == 2) {
		return "$day $clock";
	}
	elsif($style == 1) {
		return $clock;
	}
	elsif($style == -1) {
		return "$year$sep1$month$sep1$day";
	}
	elsif($style == -2) {
		return "$month$sep1$day";
	}
	else {
		return "$year$sep1$month$sep1$day$sep3$clock";
	}
}
sub run {
	#print STDERR "\t@_\n";
	return (system(@_) == 0);
	return 1;
}
sub execute {
	my %OPTS;
	my @ARGV = @_;
	if(@ARGV)
	{
	    require Getopt::Long;
	    Getopt::Long::GetOptionsFromArray(\@ARGV,\%OPTS,@OPTIONS);
	}
	else {
		$OPTS{'help'} = 1;
	}
	if($OPTS{'help'} or $OPTS{'manual'}) {
		require Pod::Usage;
		exit Pod::Usage::pod2usage(-exitval=>"NOEXIT",-verbose=>1);
	}
	
	
	my $cmd = shift(@ARGV);
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
	elsif($CMD eq 'RENAME') {
		exit Babes::Rename::process(\%OPTS,@ARGV);
	}
	elsif($CMD eq 'FOLLOW') {
		exit Babes::Follow::process(\%OPTS,@ARGV);
	}
	else {
		die("Command not found: $cmd\n");
	}

}

1;
#######################################################################
package Babes::Follow;
sub edit_file {
	my $id = shift;
	my $name = shift;
	my $disable = shift;
	my $edited;
	foreach my $file (@_) {
		my $modified;
		my @data;
		#print STDERR "    $file ...\n";
		if(! -f $file) {
			print STDERR "    Ignored, file not exist: $file\n";
			next;
		}
		elsif(open FI,'<',$file) {
			foreach my $line (<FI>) {
				my $linechanged;
				chomp($line);
				my @cols = split(/\s*\t\s*/,$line);
				foreach my $col(@cols) {
					if($col eq $id) {
						$modified = 1;
						$linechanged = 1;
					}
				}
				if($linechanged) {
					my $newline = join("\t",@cols);
					print STDERR "    $line\n  =>",join("\t",@cols),"\n";  
					$line = $newline;
				}
				push @data,$line,"\n";
			}
			close FI;
			if($modified) {
				$edited = 1;
				if(open FO,'>',$file) {
					print FO @data;
					close FO;
					print STDERR "  Modified $file\n";
				}
				else {
					print STDERR "  Error opening $file: $!\n";
				}
				
			}
		}
		else {
			print STDERR "  Error opening $file: $!\n";
			next;
		}
	}
	return $edited ? 0 : 1;
}

sub run {
	goto &Babes::run;
}

sub collect_files {
	my $OPTS = shift;
	my $dirname = shift;
	
	my @EXPS;
	foreach my $dir(@Babes::Rename::DBDIR) {
		push @EXPS,catdir($dir,'*','database.sq');
		push @EXPS,catdir($dir,'*','follows.sq');
		push @EXPS,catdir($dir,'*','follows.txt');
	}
	my @files;
	foreach my $exp(@EXPS) {
		foreach my $file(bsd_glob($exp)) {
			if($OPTS->{hosts}) {
				if($file !~ m/$OPTS->{hosts}/i) {
					#print STDERR "  Not match /$OPTS->{hosts}/, ignored: $file\n";
					next;
				}
			}
			#print STDERR "  Collected file: $file\n";
			push @files,$file;
		}
	}
	return @files;
}

sub process {
	my $OPTS = shift;
	my $oldname = shift;
	my $newname = shift;
	if($OPTS->{reposter}) {
		if(!$newname) {
			$newname = "#Reposter/$oldname";
		}
		else {
			$newname = "#Reposter/$newname";
		}
	}
	if($OPTS->{revert} or $OPTS->{reverse}) {
		($oldname,$newname) = ($newname,$oldname);
	}
	print STDERR "Renaming $oldname => $newname\n";
	my @files = collect_files($OPTS,$oldname);
	my $exit1 = edit_file($oldname,$newname,@files);
	
	my $exit2 = 0;

	if($OPTS->{move}) {
		delete $OPTS->{reposter};
		print STDERR "Moving directory $oldname => $newname\n";
		$exit2 = run('mv','-v','--',$oldname,$newname) ? 0 : 1;
	}
	return 1 if($exit1 or $exit2);
	return 0;
}

1;
#######################################################################
package Babes::Rename;
use File::Spec::Functions qw/catfile catdir/;
use File::Glob qw/bsd_glob/;
use strict;

#/myplace/workspace/perl/urlrule/sites
our @DBDIR = qw{
	sites
	../sites
	../../sites
	urlrule/sites
	../urlrule/sites
	../../urlrule/sites
};

sub edit_file {
	my $old = shift;
	my $new = shift;
	my $edited;
	foreach my $file (@_) {
		my $modified;
		my @data;
		#print STDERR "    $file ...\n";
		if(! -f $file) {
			print STDERR "    Ignored, file not exist: $file\n";
			next;
		}
		elsif(open FI,'<',$file) {
			foreach my $line (<FI>) {
				my $linechanged;
				chomp($line);
				my @cols = split(/\s*\t\s*/,$line);
				foreach my $col(@cols) {
					if($col eq $old) {
						$col = $new;
						$modified = 1;
						$linechanged = 1;
					}
				}
				if($linechanged) {
					my $newline = join("\t",@cols);
					print STDERR "    $line\n  =>",join("\t",@cols),"\n";  
					$line = $newline;
				}
				push @data,$line,"\n";
			}
			close FI;
			if($modified) {
				$edited = 1;
				if(open FO,'>',$file) {
					print FO @data;
					close FO;
					print STDERR "  Modified $file\n";
				}
				else {
					print STDERR "  Error opening $file: $!\n";
				}
				
			}
		}
		else {
			print STDERR "  Error opening $file: $!\n";
			next;
		}
	}
	return $edited ? 0 : 1;
}

sub run {
	goto &Babes::run;
}

sub collect_files {
	my $OPTS = shift;
	my $dirname = shift;
	
	my @EXPS;
	foreach my $dir(@Babes::Rename::DBDIR) {
		push @EXPS,catdir($dir,'*','database.sq');
		push @EXPS,catdir($dir,'*','follows.sq');
		push @EXPS,catdir($dir,'*','follows.txt');
	}
	my @files;
	foreach my $exp(@EXPS) {
		foreach my $file(bsd_glob($exp)) {
			if($OPTS->{hosts}) {
				if($file !~ m/$OPTS->{hosts}/i) {
					#print STDERR "  Not match /$OPTS->{hosts}/, ignored: $file\n";
					next;
				}
			}
			#print STDERR "  Collected file: $file\n";
			push @files,$file;
		}
	}
	return @files;
}

sub process {
	my $OPTS = shift;
	my $oldname = shift;
	my $newname = shift;
	if($OPTS->{reposter}) {
		if(!$newname) {
			$newname = "#Reposter/$oldname";
		}
		else {
			$newname = "#Reposter/$newname";
		}
	}
	if($OPTS->{revert}) {
		($oldname,$newname) = ($newname,$oldname);
	}
	print STDERR "Renaming $oldname => $newname\n";
	my @files = collect_files($OPTS,$oldname);
	my $exit1 = edit_file($oldname,$newname,@files);
	
	my $exit2 = 0;

	if($OPTS->{move}) {
		delete $OPTS->{reposter};
		print STDERR "Moving directory $oldname => $newname\n";
		$exit2 = run('mv','-v','--',$oldname,$newname) ? 0 : 1;
	}
	return 1 if($exit1 or $exit2);
	return 0;
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
	goto &Babes::run;
}

sub move_to {
	my $OPTS = shift;
	my $dstd = shift;
	my %clips;
	my $exit = 0;
	if($OPTS->{clips} or $OPTS->{trash} or $OPTS->{into}) {
		foreach my $srcd (@_) {
#			print STDERR $srcd,"\n";
			foreach my $file (glob("$srcd/*/*/*.*")) {
#				print STDERR $file,"\n";
				if($file =~ m/([^\/]+)\/[^\/]+\/([^\/]+)\/([^\/]+?)\.(mov\.3in1\.jpg|mov|flv|mp4|f4v|mpeg|png|gif|jpg)$/) {
					$clips{$file} = "$1_$3_$2.$4";
				}
			}
		}
	}

	unless(-d $dstd or mkdir $dstd) {
		print STDERR "Error creating $dstd\n";
		return 2;
	}

	if($OPTS->{clips} or $OPTS->{into}) {
		print STDERR "Move files into <$dstd>:\n";
		foreach my $src (keys %clips) {
			my $dst = catfile($dstd,$clips{$src});
			print STDERR "    <= " . $clips{$src} . "\n";
			$exit = run('mv','--',$src,$dst);
		}
		$dstd = $MOVE_TRASH_DIR if($OPTS->{clips});
		unless(-d $dstd or mkdir $dstd) {
			print STDERR "Error creating directory <$dstd>\n";
			return 2;
		}
	}
	elsif($OPTS->{trash}) {
		print STDERR "Delete files in:\n";
		foreach my $src (keys %clips) {
			print STDERR "    XX $src\n";
			$exit = run('rm','--',$src);
		}
	}
	if($OPTS->{into}) {
		foreach(@_) {
			if(open FO,'>>',catfile($_,'move_into.txt')) {
				print FO '' . &Babes::strtime() . ": <" . $dstd . ">\n";
				print FO "\t" . join("\n\t",keys %clips) . "\n";
				close FO;
			}
		}
	}
	else {
		print STDERR "Move directories into <$dstd>:\n";
		foreach(@_) {
			print STDERR "    <= $_\n";
			$exit = run('mv','-v','-t',$dstd,'--',$_);
		};
	}

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

	if($OPTS->{into}) {
		return move_to($OPTS,$OPTS->{into},@_);
	}

	my $DST = shift;
	unless(-d $DST or mkdir $DST) {
		print STDERR "Error creating $DST\n";
		return 2;
	}


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
	goto &Babes::run;
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
	if($OPTS->{trash} or $OPTS->{reposter} or $OPTS->{clips}) {
		delete $OPTS->{junction};
	}
	else {
		$OPTS->{junction} = 1;
		$DST = shift;
	}

	my $INTO = $OPTS->{into};
	delete $OPTS->{into};

	if(!@_) {
		die("Usage: $0 close [options] target_directory source_directory\n");
	}
	
	foreach my $SRC (@_) {
		Babes::Clean::process($OPTS,$SRC) if($OPTS->{'clean'});
		Babes::Update::process($OPTS,$SRC);
		if($DST) {
			Babes::Move::process($OPTS,$DST,$SRC);
		}
		else {
			Babes::Move::process($OPTS,$SRC);
		}
		if($OPTS->{junction} and $INTO) {
			Babes::Move::process({'into'=>$INTO},$SRC);
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
	push @prog,'--images' if($OPTS->{images});
	push @prog,'--videos' if($OPTS->{videos});
	push @prog,'--include',$OPTS->{include} if($OPTS->{include});
	push @prog,'--exclude',$OPTS->{exclude} if($OPTS->{exclude});
	my $exit = 0;
	foreach(@_) {
		$exit = &Babes::run(@prog,'-d',$_);
	}
	return $exit;
}
1;
#######################################################################
&Babes::execute(@ARGV);

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
