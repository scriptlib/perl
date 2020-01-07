#!/usr/bin/perl 
# $Id$
#===============================================================================
#         NAME: list-dir
#  DESCRIPTION: 
#       AUTHOR: xiaoranzzz <xiaoranzzz@MYPLACE>
# ORGANIZATION: MyPlace HEL ORG.
#      VERSION: 1.0
#      CREATED: 2019-12-01 03:21
#     REVISION: ---
#===============================================================================
package MyPlace::Script::list_dir;
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

my $output = shift;
die("Usage: $0 <output> dirs...\n") unless(@ARGV);

foreach(@ARGV) {
	print STDERR "Listing $_ \n";
	if(open FO,">>","$_/$output") {
		foreach my $f (glob("$_/*")) {
			next if($f =~ m/\/\./);
			next if($f eq "$_/$output");
			print STDERR " -- $f\n";
			print FO $f,"\n";
		}
		close FO;
		print STDERR ">>$_/$output";
	}
	else {
		print STDERR "  Error opening $_/$output \n";
	}
}


__END__

=pod

=head1  NAME

list-dir - PERL script

=head1  SYNOPSIS

list-dir [options] ...

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

    2019-12-01 03:21  xiaoranzzz  <xiaoranzzz@MYPLACE>
        
        * file created.

=head1  AUTHOR

xiaoranzzz <xiaoranzzz@MYPLACE>

=cut

#       vim:filetype=perl
