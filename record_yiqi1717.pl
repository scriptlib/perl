#!/usr/bin/env perl 
# $Id$
#===============================================================================
#         NAME: play_yixia
#  DESCRIPTION: 
#       AUTHOR: xiaoranzzz <xiaoranzzz@MyPlace>
# ORGANIZATION: MyPlace HEL ORG.
#      VERSION: 1.0
#      CREATED: 2016-08-14 00:54
#     REVISION: ---
#===============================================================================
package MyPlace::Script::play_yixia;
use strict;
our $VERSION = 'v0.1';
my @OPTIONS = qw/
	help|h|? 
	manual|man
	wait|sleep|w|s=i
	no-preview|np
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
my $id = shift;
my $name = shift;
my $start = shift;
my $title = $id . ($name ? "_$name" : "");
$start = &strtime(time,4,"","","") unless($start);
my $output = "yiqi1717_" . $title . "_" . $start . ".flv";
my $url = 'http://yiqihdl.8686c.com/pajia/' . $id . '.flv';

		print STDERR "Checking the show ... \n";
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
		exit 0 if(not $show_online);
		print STDERR "  OK\n";



system("mintty_bg","-h","error","-t", $name, "-e","record_yiqi1717_start",$id,$name,$start,$output);
exit 0;






__END__

=pod

=head1  NAME

play_yixia - PERL script

=head1  SYNOPSIS

play_yixia [options] ...

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

    2016-08-14 00:54  xiaoranzzz  <xiaoranzzz@MyPlace>
        
        * file created.

=head1  AUTHOR

xiaoranzzz <xiaoranzzz@MyPlace>

=cut

#       vim:filetype=perl
