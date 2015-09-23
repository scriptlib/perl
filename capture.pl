#!/usr/bin/perl -w
# $Id$
package MyPlace::Script::capture;
use File::Glob qw/bsd_glob/;
use strict;

our $VERSION = 'v0.1';
my @OPTIONS = qw/
	help|h|? 
	manual|man
	mplayer|player=s
	start|ss|s=i
	count|c=i
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
	my $v = $OPTS{'help'} ? 1 : 2;
	Pod::Usage::pod2usage(-exitval=>$v,-verbose=>$v);
    exit $v;
}

sub _glob_files {
	goto &bsd_glob;
}


sub list_files_exclude_exts {
	my $dir = shift;
	my $include = shift;
	my @exts = @_;
	my @subdirs;
	my @result;
	my %files;
	my %selected;
#	print STDERR "Processing $dir/\n";
	foreach (_glob_files("$dir/*")) {
		#print STDERR $_,"\n";
		$files{$_} = 1;
		next if(m/\.$/);
		if(-d $_) {
			push @subdirs,$_;
		}
		elsif(m/$include/) {
			$selected{$_} = $1;
		}
	}
	foreach(keys %files) {
		next unless ($selected{$_});
		my $basename = $selected{$_};
		my $excluded;
		foreach my $ext(@exts) {
			if($files{$basename . $ext}) {
				$excluded = 1;
				last;
			}
		}
		push @result,$_ unless($excluded);
	}
	foreach(@subdirs) {
		push @result,list_files_exclude_exts($_,$include,@exts);
	}
	return @result;
}
sub get_videos_without_images {
	my $dir = shift;
	return list_files_exclude_exts(
		$dir,
		qr/^(.+)\.(?:mov|mp4|avi|flv|f4v|mpg|mpeg|3gp|ts|wmv|rmvb|rm)$/,
		qw/
			.mov.3in1.jpg
			.jpg
			.png
			.gif
			.1.jpg
			.2.jpg
			.3.jpg
			.4.jpg
			.5.jpg
			.p.jpg
			.p.1.jpg
			.p.2.jpg
			.p.3..jpg
			.p.4.jpg
			.p.5.jpg

		/,
	);
}

sub run {
	print STDERR join(" ",@_),"\n";
	return system(@_) == 0;
}

sub process_files {
	my $OPTS = shift;
	if(!@_) {
		print STDERR "Nothing to do!\n";
		return 0;
	}
	my  @prog = ($OPTS->{mplayer},'-nosound');
	push @prog,'-ss', $OPTS->{start} ? $OPTS->{start} : 0;
	push @prog, '-frames', 1;
	push @prog,(qw/
			-vf screenshot
			-vo	jpeg
		/);
	foreach(@_) {
		my @dirs = split(/\//,$_);
		my $basename = pop(@dirs);
		$basename =~ s/\.[^\.]+$//;
		run(@prog,'--',$_);
		run('mv','-v','--','00000001.jpg', join("/",@dirs,$basename) . ".jpg");
	}
	return 1;
}
sub process_dir {
	my $OPTS = shift;
	my @files = get_videos_without_images(@_);
	return process_files($OPTS,@files);
}

sub process {
	my $OPTS = shift;
	my $mplayer;
	if(!$OPTS->{mplayer}) {
		foreach (qw/mplayer mplayer.exe mplayer.bat/) {
			my $which = `which $_ 2>/dev/null`;
			chomp($which);
			if($which) {
				$mplayer = $which;
				last;
			}
		}
		if(!$mplayer) {
			die("Mplayer binary not found!\n");
		}
		$OPTS->{mplayer} = $mplayer;
	}
	foreach(@_) {
		if(-d $_) {
			process_dir($OPTS,$_);
		}
		else {
			process_files($OPTS,$_);
		}
	}
	return 0;
}

exit process(\%OPTS,@ARGV);

__END__

=pod

=head1  NAME

capture - Capture screenshot for videos

=head1  SYNOPSIS

capture [options] files|directories

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

    2015-09-11 00:40  xiaoranzzz  <xiaoranzzz@MyPlace>
        
        * file created.

=head1  AUTHOR

xiaoranzzz <xiaoranzzz@MyPlace>

=cut

#       vim:filetype=perl
