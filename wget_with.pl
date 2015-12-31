#!/usr/bin/env perl 
# $Id$
#===============================================================================
#         NAME: wget_with
#  DESCRIPTION: Using wget with prodefined profiles
#       AUTHOR: xiaoranzzz <xiaoranzzz@MyPlace>
# ORGANIZATION: MyPlace HEL ORG.
#      VERSION: 1.0
#      CREATED: 2015-12-05 02:04
#     REVISION: ---
#===============================================================================
package MyPlace::Script::wget_with;
use MyPlace::String::Utils qw/strtime/;
use strict;

our $VERSION = 'v0.1';
my @OPTIONS = qw/
	help|h|? 
	manual|man
	profile|pro=s
	tee=s
/;
my %OPTS;
my @OLD_ARGV = @ARGV;
if(@ARGV)
{
    require Getopt::Long;
	Getopt::Long::Configure('pass_through');
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

sub newmsg {
	return strtime(),": " unless(@_);
	my $s1 = $_[0];
	if($s1 eq ':copy_raw') {
		shift;
		return @_;
	}
	else {
		return strtime(),": ",@_;
	}
}


my $LOGFILE;
my $FH_LOG;

if(defined $OPTS{tee}) {
	$FH_LOG = 'ERROR' if($OPTS{tee} eq 'STDERR');
}
else {
	foreach(@ARGV) {
		next unless(m/^(?:http|ftp|https):\/\/(.+)$/);
		$OPTS{tee} = $1;
		$OPTS{tee} =~ s/\//_/g;
		$OPTS{tee} .= "_wget.log";
		$OPTS{tee} =~ s/__+/_/g;
		last;
	}
}
if(!defined $OPTS{tee}) {
	$OPTS{tee} = 'wget_with.log';
}

sub tee {
	if(!defined $FH_LOG) {
		$LOGFILE = shift;
		if(!$LOGFILE) {
			$FH_LOG = 'ERROR';
		}
		elsif(open $FH_LOG,'>>',$LOGFILE) {
			#print STDERR newmsg("Logging to <$LOGFILE>\n");
			#tee("Open logfile <$LOGFILE>\n");
		}
		else {
			$FH_LOG = 'ERROR';
			tee("Error opening file <$LOGFILE>:\n");
		}
	}
	my @msg = newmsg(@_);
	print STDERR @msg;
	print $FH_LOG @msg unless($FH_LOG eq 'ERROR');
	return @msg
}


my %PROFILE = (
	'default'=>[qw{
		-e robots=off
		--progress=bar
		--restrict-file-names=windows
		--show-progress
		-o /dev/stdout
	}],
	'ftp'=>[qw{-X /icons/,/icon/ -np -r --reject-regex C=}],
	'html'=>[qw{-x -N -r -kEp}],
	'dir'=>[qw{-x -N -np -nH -r -l 0}],
	'mirror'=>[qw{--mirror}],
);
push @{$PROFILE{default}}, '-U','Mozilla/5.0 (X11; U; Linux i686; en-US; rv:1.9.0.3) Gecko/2008092416 Firefox/3.0.3 Firefox/3.0.1';

my @CMDLINE = ('wget');
my $profile = $OPTS{profile} || 'default';
die ("Profile not exist: $profile\n") unless($PROFILE{$profile});

if($profile ne 'default') {
	push @CMDLINE,@{$PROFILE{default}};
}
push @CMDLINE,@{$PROFILE{$profile}};

tee($OPTS{tee},join(" ",$0,@OLD_ARGV),"\n");
tee("Command> ",join(" ",@CMDLINE,@ARGV),"\n");
tee("  Start> \n");
if(!$OPTS{tee}) {
	exit system(@CMDLINE,@ARGV) ==0;
}
if(!open FI,'-|',@CMDLINE,@ARGV) {
		tee("Error bring up <wget>: $!\n");
		return undef;
}
tee("Executing>\n");
tee(":copy_raw",'-'x40,"\n");
while(<FI>) {
	tee(":copy_raw","  ",$_);
}
close FI;
tee(":copy_raw",'-'x40,"\n");
tee("Stop\n");
close $FH_LOG;

__END__

=pod

=head1  NAME

wget_with - PERL script

=head1  SYNOPSIS

wget_with -profile <profile name> [options] ...

	wget_with -profile html http://gambaswiki.org
	wget_with -profile ftp  http://iweb.dl.sourceforge.net/project/hbasic/

=head1  OPTIONS

=over 12

=item B<--profile>,B<--pro>

Execute WGET with specified profile 

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

    2015-12-05 02:04  xiaoranzzz  <xiaoranzzz@MyPlace>
        
        * file created.

=head1  AUTHOR

xiaoranzzz <xiaoranzzz@MyPlace>

=cut

#       vim:filetype=perl
