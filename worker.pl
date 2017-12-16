#!/usr/bin/env perl 
# $Id$
#===============================================================================
#         NAME: worker
#  DESCRIPTION: 
#       AUTHOR: xiaoranzzz <xiaoranzzz@MyPlace>
# ORGANIZATION: MyPlace HEL ORG.
#      VERSION: 1.0
#      CREATED: 2017-10-09 00:22
#     REVISION: ---
#===============================================================================
package MyPlace::Script::worker;
use strict;

our $VERSION = 'v0.1';
my @OPTIONS = qw/
	help|h|? 
	manual|man
	sites|s=s
	action|command|a=s
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

my @cmds = ('urlrule_worker',"sites");
if($OPTS{sites}) {
	push @cmds,$OPTS{sites};
}
else {
	push @cmds,"*";
}
if($OPTS{action}) {
	push @cmds,$OPTS{action};
}
else {
	push @cmds,"DOWNLOADER";
}
exec(@cmds,@ARGV);

__END__

=pod

=head1  NAME

worker - PERL script

=head1  SYNOPSIS

worker [options] ...

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

    2017-10-09 00:22  xiaoranzzz  <xiaoranzzz@MyPlace>
        
        * file created.

=head1  AUTHOR

xiaoranzzz <xiaoranzzz@MyPlace>

=cut

#       vim:filetype=perl
