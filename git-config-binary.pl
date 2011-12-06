#!/usr/bin/perl -w
# $Id$
package MyPlace::Script::git_config_binary;

use strict;
use v5.8.0;
use MyPlace::Usage;
our $VERSION = 'v0.1';
my @GLOBAL;
my %config = (
	'pack.compression' => 0,
	'core.loosecompression' => 0,
	'core.compression' => 0,
	'gc.auto' => 0,
	'pack.packSizeLimit' => '4m',
);

sub git_config {
	my %opts = @_;
	foreach (keys %opts) {
		print STDERR "$_ => $opts{$_}\n";
		system(qw/git config/,@GLOBAL,$_,$opts{$_});
	}
}
my @pairs;
while(@ARGV) {
	my $val = shift @ARGV;
	if($val =~ m/^-/) {
		push @GLOBAL,$val;
	}
	elsif($val =~ m/^(.+)=(.+)$/) {
		push @pairs,$1,$2;
	}
	else {
		push @pairs,$val,(shift(@ARGV)); 
	}
}
&git_config(%config,@pairs);

__END__

=pod

=head1  NAME

git-config-binary - PERL script

=head1  SYNOPSIS

git-config-binary [options] ...

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

    2011-12-02 22:27  xiaoranzzz  <xiaoranzzz@myplace.hell>
        
        * file created.

=head1  AUTHOR

xiaoranzzz <xiaoranzzz@myplace.hell>

=cut

#       vim:filetype=perl
