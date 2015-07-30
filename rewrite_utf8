#!/usr/bin/perl -w
# $Id$
package MyPlace::Script::rewrite_utf8;
use strict;

our $VERSION = 'v0.1';
my @OPTIONS = qw/
	help|h|? 
	manual|man
	test|t
	reverse|r
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


my $iflag = $OPTS{reverse} ? ":utf8" : "";
my $oflag = $OPTS{reverse} ? "" : ":utf8";

if(not $OPTS{reverse}) {
	binmode STDERR , 'utf8';
}


foreach(@ARGV) {
	print STDERR "Rewrite [$_] ...\n";
	my @old;

	if(open FI,"<$iflag",$_) {
	#if(open FI,"<",$_) {
		@old = <FI>;	
		close FI;
	}
	else {
		print STDERR ("Error opening $_ for read: $!\n");
	}

	if($OPTS{test}) {
		print STDERR @old;
	}
	elsif(open FO,">$oflag",$_) {
		print FO @old;
		close FO;
	}
	else {
		print STDERR ("Error opening $_ for read: $!\n");
	}
	
}



__END__

=pod

=head1  NAME

rewrite_utf8 - PERL script

=head1  SYNOPSIS

rewrite_utf8 [options] ...

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

    2014-10-26 01:27  xiaoranzzz  <xiaoranzzz@MyPlace>
        
        * file created.

=head1  AUTHOR

xiaoranzzz <xiaoranzzz@MyPlace>

=cut

#       vim:filetype=perl
