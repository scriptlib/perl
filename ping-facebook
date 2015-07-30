#!/usr/bin/perl -w
# $Id$
package MyPlace::Script::ping_facebook;

use strict;
use v5.8.0;
use MyPlace::Usage;
our $VERSION = 'v0.1';

my %OPTS;
my @OPTIONS = qw/help|h|? version|ver edit-me manual|man/;
if(@ARGV)
{
    require Getopt::Long;
    Getopt::Long::GetOptions(\%OPTS,@OPTIONS);
    MyPlace::Usage::Process(\%OPTS,$VERSION);
}
my $hostfile = "/etc/hosts";
my %table;
my @hosts;
open FI,"<",$hostfile or die("$!\n");
while(<FI>) {
	chomp;
	if(m/^\s*(\d+\.\d+\.\d+\.\d+)\s+([^\s]*(facebook\.com|fbcdn\.net|facebook\.com|tfbnw\.net))\s*$/) {
		$table{$2} = $1;
		push @hosts,$2;
	}
}
close FI;
my @failed;
foreach(@hosts) {
	print STDERR "TESTING $_ = $table{$_}:\n";
	if(system("curl --connect-timeout 10 $table{$_}	>/dev/null") == 0) {
		print STDERR "\t[OK]\n";
	}
	else {
		push @failed,$_;
	}
}
if(@failed) {
	print STDERR "Follow entries failed:\n";
	print join("\n",@failed),"\n";
}
else {
	print STDERR "Every ip works.\n";
}


__END__

=pod

=head1  NAME

ping-facebook - PERL script

=head1  SYNOPSIS

ping-facebook [options] ...

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

    2012-10-01 17:10  Administrator  <Administrator@20120524-1828>
        
        * file created.

=head1  AUTHOR

Administrator <Administrator@20120524-1828>

=cut

#       vim:filetype=perl
