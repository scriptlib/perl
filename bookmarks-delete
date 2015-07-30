#!/usr/bin/perl -w
# $Id$
package MyPlace::Script::bookmarks_delete;
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

my $cond = shift;
print STDERR "Delete bookmarks that match /$cond/i\n";
my $deleting = undef;
my $DEBUG = 0;
my $total = 0;
my $left = 0;
while(<>) {
	print STDERR $_ if($DEBUG);
	$total++ if(m/<(?:DT|dt)>/);
	if($deleting and m/<(?:DT|dt|dl|DL|P|p)>/) {
		$deleting = undef;
	}

	if($deleting) {
		print STDERR "\tDeleted\n" if($DEBUG);
		#print STDERR "[DELETE] $_";
		next;
	}
	elsif(m/$cond/i) {
		$deleting = 1;
		print STDERR "\tDeleted\n" if($DEBUG);
		#print STDERR "[DELETE] $_";
		next;
	}
	$left++ if(m/<(?:DT|dt)>/);
	print STDERR "\tKeep\n" if($DEBUG);
	print $_ if(!$DEBUG);
}
print STDERR "Originally $total bookmarks, now reduce to $left\n";



__END__

=pod

=head1  NAME

bookmarks-delete - PERL script

=head1  SYNOPSIS

bookmarks-delete [options] ...

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

    2014-08-11 00:33  xiaoranzzz  <xiaoranzzz@MyPlace>
        
        * file created.

=head1  AUTHOR

xiaoranzzz <xiaoranzzz@MyPlace>

=cut

#       vim:filetype=perl
