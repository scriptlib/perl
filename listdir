#!/usr/bin/perl -w
# $Id$
package MyPlace::Script::listdir;
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

my $dir = shift;
my $exp = "^$dir";
$exp =~ s/([\/\\])/\\$1/g;
$exp = qr/$exp\//o;
my $name = shift;
$name = qr/$name$/o if($name);
print $dir,$name ? "\t[$name]" : "","\n\n";
open FI,'-|','find',$dir or die("Error find $dir: $!\n");
if($name) {
	while(<FI>) {
		next unless(m/$name/i);
		s/$exp//;
		s/^[\/\\]+//;
		print $_;
	}
}
else {
	while(<FI>) {
		$_ =~ s/$exp//;
		$_ =~ s/^[\/\\]+//;
		print $_;
	}
}
close FI;


__END__

=pod

=head1  NAME

listdir - PERL script

=head1  SYNOPSIS

listdir [options] ...

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

    2014-06-24 23:38  xiaoranzzz  <xiaoranzzz@MyPlace>
        
        * file created.

=head1  AUTHOR

xiaoranzzz <xiaoranzzz@MyPlace>

=cut

#       vim:filetype=perl
