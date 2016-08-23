#!/usr/bin/env perl 
# $Id$
#===============================================================================
#         NAME: record_yiqi1717_start
#  DESCRIPTION: 
#       AUTHOR: xiaoranzzz <xiaoranzzz@MyPlace>
# ORGANIZATION: MyPlace HEL ORG.
#      VERSION: 1.0
#      CREATED: 2016-08-15 02:55
#     REVISION: ---
#===============================================================================
package MyPlace::Script::record_yiqi1717_start;
use strict;

our $VERSION = 'v0.1';
my @OPTIONS = qw/
	help|h|? 
	manual|man
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

use MyPlace::String::Utils qw/strtime/;

my $wait = $OPTS{wait} || 10;
my $seconds = $OPTS{seconds} || 600;
my $id = shift;
my $name = shift;
my $start = shift(@ARGV) || strtime(time,4,'','','');
my $title = $id . ($name ? "_$name" : "");
my $url = 'http://yiqihdl.8686c.com/pajia/' . $id . '.flv';
my $restart = !$OPTS{'no-ask'};
my $preview = !$OPTS{'no-preview'};
while($start) {
RECORDING:
	if($restart) {
		$preview = undef;
		printf STDERR "%10s : %s\n","Y","Recording without preview";
		printf STDERR "%10s : %s\n","R","Recording with preview";
		printf STDERR "%10s : %s\n","...","Exit";
		print STDERR "Start recording for $name $id ? [YOUR ANSWER:] ";
		my $answer = <STDIN>;
		if($answer =~ m/^([YyRr])(\d+)$/) {
			$answer = lc($1);
			$seconds = 60 * $2;
		}
		else {
			$answer = lc(substr($answer,0,1));
		}
		if($answer eq 'y') {
			$start = strtime(time(),4,"","","");
			$preview = undef;
		}
		elsif($answer eq "r") {
			$start = strtime(time(),4,"","","");
			$preview = 1;
		}
		else {
			last;
		}
		print STDERR "Checking the show ...\n";
		my $show_online = 1;
		if(open FI,'-|','curl','--silent','-I',$url) {
			foreach(<FI>) {
				if(index($_,'HTTP/1.1 404 Not Found')>=0) {
					print STDERR "    $_";
					print STDERR "  NO, the show is END\n";
					$show_online = 0;
					last;
				}
			}
		}
		close FI;
		next if(not $show_online);
	}
	print STDERR "  OK\n";
	$restart = 1;
	my $output = "yiqi1717_" . $title . "_" . $start . ".flv";
	system("touch","..","../..","../../..","../../../../");
	if($preview) {
		print STDERR "Preview will start in $wait seconds ...\n";
		system("exec_delay $wait kmplayer.bat \"$output\" 2>&1 1>/dev/null &");
	}
	print "\033]2;$name $id [RECORDING]\007";
	printf STDERR "%10s %10s [%4d分钟]\n",$name,$id,$seconds / 60;
	print STDERR "Start caching $url ...\n";
	print STDERR "\tBEGIN: " . localtime() . "\n";
	print STDERR "\t$url\n";
	print STDERR "\t$output\n";
	print STDERR "-"x80,"\n";
	system("curl","-m",$seconds,"--url",$url,"-o",$output);
	print STDERR "\n","-"x80,"\n";
	print STDERR "\tEND: " . localtime() . "\n";
	print STDERR "$name\t$id\n";
	print "\033]2;<END>$name $id\007";
}

__END__

=pod

=head1  NAME

record_yiqi1717_start - PERL script

=head1  SYNOPSIS

record_yiqi1717_start [options] ...

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

    2016-08-15 02:55  xiaoranzzz  <xiaoranzzz@MyPlace>
        
        * file created.

=head1  AUTHOR

xiaoranzzz <xiaoranzzz@MyPlace>

=cut

#       vim:filetype=perl
#!/usr/bin/env perl 
#===============================================================================
#
#         FILE: record_yiqi1717_start.pl
#
#        USAGE: ./record_yiqi1717_start.pl  
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
#      CREATED: 2016/08/15  2:55:29
#     REVISION: ---
#===============================================================================

use strict;
use warnings;
use utf8;


