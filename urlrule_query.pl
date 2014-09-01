#!/usr/bin/perl -w
# $Id$
package MyPlace::Script::urlrule_query;
use strict;
use MyPlace::URLRule::SimpleQuery;

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
my $key = shift;
my $SQ = new MyPlace::URLRule::SimpleQuery(@ARGV);
my ($status,@result) = $SQ->query($key);
if($status) {
	foreach my $item (@result) {
		next unless($item);
		print join("\t",@{$item}),"\n";
	}
}
else {
	print STDERR "Error: ",join("\n",@result),"\n";
	exit 1;
}


__END__

=pod

=head1  NAME

urlrule_query - PERL script

=head1  SYNOPSIS

urlrule_query [options] ...

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

    2014-08-10 00:52  xiaoranzzz  <xiaoranzzz@MyPlace>
        
        * file created.

=head1  AUTHOR

xiaoranzzz <xiaoranzzz@MyPlace>

=cut

#       vim:filetype=perl
