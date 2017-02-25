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
	endpos|ep=s
	startpos|sp=s
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

my $app = "/myplace/system/app/multimedia/MPlayer/mencoder.exe";
my @opts = qw/
	-quiet
/;
my @flv = qw/
	-of lavf -oac mp3lame -lameopts abr:br=56
	-srate 22050 -ovc lavc
	-lavcopts vcodec=flv:vbitrate=500:mbd=2:mv0:trell:v4mv:last_pred=3
/;
my @copy = qw/
	-of lavf -oac mp3lame -ovc copy
/;
my @mp4 = qw/
	-of lavf -oac mp3lame -ovc lavc -lavcopts vcodec=mpeg4
/;

if($OPTS{flv}) {
	push @opts,@flv;
}
elsif($OPTS{copy}) {
	push @opts,@copy;
}
elsif($OPTS{mp4}) {
	push @opts,@mp4;
}
else {
	push @opts,@mp4;
}
if($OPTS{maxtime}) {
	push @opts,"-endpos",$OPTS{maxtime};
}
if($OPTS{output}) {
	push @opts,"-o",$OPTS{output};
}
push @opts,"-endpos",$OPTS{endpos} if($OPTS{endpos});
push @opts,"-startpos",$OPTS{startpos} if($OPTS{startpos});
exec($app,@ARGV,@opts);

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


