#!/usr/bin/env perl 
# $Id$
#===============================================================================
#         NAME: record_rtmp
#  DESCRIPTION: 
#       AUTHOR: xiaoranzzz <xiaoranzzz@MyPlace>
# ORGANIZATION: MyPlace HEL ORG.
#      VERSION: 1.0
#      CREATED: 2017-02-26 02:21
#     REVISION: ---
#===============================================================================
package MyPlace::Script::record_rtmp;
use strict;

our $VERSION = 'v0.1';
my @OPTIONS = qw/
	help|h|? 
	manual|man
	maxtime|max|m=i
	output|o=s
	flv
	mp4
	copy
	x264
	endpos|ep=s
	startpos|sp=s
	dump
	test
/;
my %OPTS;
if(@ARGV)
{
    require Getopt::Long;
	#Getopt::Long::Configure('pass_through',1);
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

my $mencoder = "/myplace/system/app/multimedia/MPlayer/mencoder.exe";
my $mplayer = "/myplace/system/app/multimedia/MPlayer/mplayer.exe";
my $app = $mencoder;
my @opts = qw/
	-quiet
/;
my @flv = qw/
	-of lavf -oac mp3lame -lameopts abr:br=56
	-srate 22050 -ovc lavc
	-lavcopts vcodec=flv:vbitrate=500:mbd=2:mv0:trell:v4mv:last_pred=3
/;
my @flv2 = qw/
	-of lavf -oac mp3lame -ovc lavc
	-lavcopts vcodec=flv -ni
/;
my @copy = qw/
	-of lavf -oac mp3lame -ovc copy
/;
my @x264 = qw/
	-of lavf -oac faac
	-ovc x264
/;
my @mp4 = qw/
	 -of lavf
	 -lavfopts format=mpeg4
	 -oac lavc
	 -lavcopts acodec=ac3
	 -ovc lavc
	 -lavcopts vcodec=mpeg4:mbd=2:trell:v4mv:last_pred=2:dia=-1:vmax_b_frames=2:vb_strategy=1:cmp=3:subcmp=3:precmp=0:vqcomp=0.6:turbo
	 -ni
/;
#-of lavf
#	 -lavfopts format=mpeg4
my @x264 = qw/
	 -oac faac
	 -ovc x264
/;
my @test = qw/
	-oac faac
	-ovc copy
/;
#:mbd=2:mv0:trell:v4mv:last_pred=3
#lavc -lavcopts vcodec=mpeg4
#-lavcopts vcodec=h264

use File::Temp qw/ tempfile /;
my (undef, $tmpname) = tempfile("record_rtmp_XXXX", OPEN => 0,DIR=>'',EXT=>".dat");

if($OPTS{output}) {
	$OPTS{write} = $OPTS{output};
	$OPTS{output} = $tmpname . ".downloading";
}
else {
	$OPTS{write} = $tmpname;
	$OPTS{output} = $tmpname . ".downloading";
}

if($OPTS{dump}) {	
	$app = $mplayer;
	push @opts,(qw/
		-noar -noconsolecontrols -nojoystick -nolirc -nomouseinput -nofontconfig
		-nosub
	/);
	push @opts,"-dumpstream","-dumpfile",$OPTS{output};
	if($OPTS{maxtime}) {
		$OPTS{maxtime} = ((0+$OPTS{maxtime})/60)*(5*1024) . "kb";
	}
}
else {
	push @opts,'-o',$OPTS{output};
	if($OPTS{flv}) {
		push @opts,@flv;
	}
	elsif($OPTS{copy}) {
		push @opts,@copy;
	}
	elsif($OPTS{mp4}) {
		push @opts,@mp4;
	}
	elsif($OPTS{x264}) {
		push @opts,@x264;
	}
	elsif($OPTS{test}) {
		push @opts,@test;
	}
	else {
		push @opts,@x264;
	}
}
if($OPTS{maxtime}) {
	push @opts,"-endpos",$OPTS{maxtime};
}
push @opts,"-endpos",$OPTS{endpos} if($OPTS{endpos});
push @opts,"-startpos",$OPTS{startpos} if($OPTS{startpos});
print STDERR join(" ",$app,@ARGV,@opts),"\n";
system($app,@ARGV,@opts);
if(-f $OPTS{output}) {
	rename($OPTS{output},$OPTS{write});
	print STDERR "->save to $OPTS{write}\n";
}

__END__

=pod

=head1  NAME

record_rtmp - PERL script

=head1  SYNOPSIS

record_rtmp [options] ...

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

    2017-02-26 02:21  xiaoranzzz  <xiaoranzzz@MyPlace>
        
        * file created.

=head1  AUTHOR

xiaoranzzz <xiaoranzzz@MyPlace>

=cut

#       vim:filetype=perl
#!/usr/bin/env perl 
#===============================================================================
#
#         FILE: record_rtmp.pl
#
#        USAGE: ./record_rtmp.pl  
#
#  DESCRIPTION: 
#
#      OPTIONS: ---
# REQUIREMENTS: ---
#         BUGS: ---
#        NOTES: ---
#       AUTHOR: Eotect Nahn (eotect), eotect@myplace.hel
# ORGANIZATION: MyPlace HEL. ORG.
#      VERSION: 1.0
#      CREATED: 2017/02/26  2:21:43
#     REVISION: ---
#===============================================================================

use strict;
use warnings;
use utf8;


