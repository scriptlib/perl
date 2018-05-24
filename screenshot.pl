#!/usr/bin/env perl 
# $Id$
#===============================================================================
#         NAME: screenshot
#  DESCRIPTION: 
#       AUTHOR: xiaoranzzz <xiaoranzzz@MyPlace>
# ORGANIZATION: MyPlace HEL ORG.
#      VERSION: 1.0
#      CREATED: 2016-04-15 03:04
#     REVISION: ---
#===============================================================================
package MyPlace::Script::screenshot;
use strict;

our $VERSION = 'v0.1';
my @OPTIONS = qw/
	help|h|? 
	manual|man
	mplayer|player=s
	start|ss|s=s
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

sub process_file {
	my $OPTS = shift;
	my $prog = shift;
	my $file = shift;
	my @dirs = split(/\//,$file);
	my $basename = pop(@dirs);
	$basename =~ s/\.[^\.]+$//;
	$basename = join("/",@dirs,$basename);
	my $dst = $basename . "_001.jpg";
	system(@$prog,'--',$_);
	my $n = 1;
	while(-f $dst) {
		$n = $n + 1;
		my $suf;
		if($n<10) {
			$suf = "00$n.jpg";
		}
		elsif($n<100) {
			$suf = "0$n.jpg";
		}
		else {
			$suf = "$n.jpg";
		}
		$dst = $basename . "_" . $suf;
	}
	system("rm","-v",$dst) if(-f $dst);
	system('mv','-v','--','00000001.jpg', $dst);
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
	my  @prog = ($OPTS->{mplayer},'-nosound');
	push @prog,'-ss', $OPTS->{start} ? $OPTS->{start} : 3;
	push @prog, '-frames', 1;
	push @prog,(qw/
			-vf screenshot
			-vo	jpeg
		/);
	foreach(@_) {
		process_file($OPTS,\@prog,$_);
	}
	return 0;
}

&process(\%OPTS,@ARGV);

__END__

=pod

=head1  NAME

screenshot - PERL script

=head1  SYNOPSIS

screenshot [options] ...

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

    2016-04-15 03:04  xiaoranzzz  <xiaoranzzz@MyPlace>
        
        * file created.

=head1  AUTHOR

xiaoranzzz <xiaoranzzz@MyPlace>

=cut

#       vim:filetype=perl
