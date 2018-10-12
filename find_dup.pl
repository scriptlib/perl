#!/usr/bin/env perl 
# $Id$
#===============================================================================
#         NAME: find_dup
#  DESCRIPTION: 
#       AUTHOR: xiaoranzzz <xiaoranzzz@MyPlace>
# ORGANIZATION: MyPlace HEL ORG.
#      VERSION: 1.0
#      CREATED: 2018-07-27 00:27
#     REVISION: ---
#===============================================================================
package MyPlace::Script::find_dup;
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
if($OPTS{'help'} or $OPTS{'manual'}) {
	require Pod::Usage;
	my $v = $OPTS{'help'} ? 1 : 2;
	Pod::Usage::pod2usage(-exitval=>$v,-verbose=>$v);
    exit $v;
}
use Digest::MD5;
my $dg = Digest::MD5->new();

my @files;
my %dup;

foreach(<>) {
	chomp;
	next unless(-f $_);
	next unless(-r $_);
	my $fh;
	if(!(open $fh,'<',$_)) {
		print STDERR "Error opening $_: $!\n";
		next;
	}
	$dg->reset();
	$dg->addfile($fh);
	my $md5 = $dg->hexdigest();
	close $fh;
	if($dup{$md5}) {
		print $_,"\n";
	}
	else {
		$dup{$md5} = 1;
	}
}



__END__

=pod

=head1  NAME

find_dup - Find files duplacated MD5SUM

=head1  SYNOPSIS

find_dup [options] [files list] ...

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

    2018-07-27 00:27  xiaoranzzz  <xiaoranzzz@MyPlace>
        
        * file created.

=head1  AUTHOR

xiaoranzzz <xiaoranzzz@MyPlace>

=cut

#       vim:filetype=perl
