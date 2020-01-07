#!/usr/bin/perl 
# $Id$
#===============================================================================
#         NAME: r-rm
#  DESCRIPTION: 
#       AUTHOR: xiaoranzzz <xiaoranzzz@MYPLACE>
# ORGANIZATION: MyPlace HEL ORG.
#      VERSION: 1.0
#      CREATED: 2019-11-29 23:48
#     REVISION: ---
#===============================================================================
package MyPlace::Script::r_rm;
use strict;

our $VERSION = 'v0.1';
my @OPTIONS = qw/
	help|h|? 
	manual|man
	force|f
	verbose|v
	recursive|r
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

my @files = @ARGV;
if(!@files) {
	die("Usage: $0 [options] files...\n");
}
my %dups;
my @args;
while(@files) {
	local $_ = shift(@files);
	next if($dups{$_});
	push @args,$_;
	print STDERR "X $_\n"; 
	$dups{$_} = 1;
	if(m/\.[^\/]+$/) {
		s/\.[^\/]+$//;
		foreach my $slim (glob($_ . ".*")) {
			next if($dups{$slim});
			push @files,$slim;
		}
	}
}
my @progs = ("/bin/rm");
push @progs,"-r" if($OPTS{recursive});
push @progs,"-v" if($OPTS{verbose});
push @progs,"-f" if($OPTS{force});
push @progs,"--",@args;
exec(@progs);

__END__

=pod

=head1  NAME

r-rm - PERL script

=head1  SYNOPSIS

r-rm [options] ...

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

    2019-11-29 23:48  xiaoranzzz  <xiaoranzzz@MYPLACE>
        
        * file created.

=head1  AUTHOR

xiaoranzzz <xiaoranzzz@MYPLACE>

=cut

#       vim:filetype=perl
