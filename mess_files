#!/usr/bin/perl -w
# $Id$
package MyPlace::Script::obscure;
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

foreach my $file(@ARGV) {
	print STDERR "messing $file ...\n";
	open FI,'<',$file or next;
	my @data = <FI>;
	close FI;
	open FO,'>',$file or next;
	print FO map {tr/AaBbCcDdEeIiKkLNQqRrSsUuWwXxYyZz0123456789/987654321abcdefghijklmnopqrstuvwxyzABCDE/,$_} @data;
	close FO;
}


__END__

=pod

=head1  NAME

obscure - PERL script

=head1  SYNOPSIS

obscure [options] ...

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

    2015-03-11 02:08  xiaoranzzz  <xiaoranzzz@MyPlace>
        
        * file created.

=head1  AUTHOR

xiaoranzzz <xiaoranzzz@MyPlace>

=cut

#       vim:filetype=perl
