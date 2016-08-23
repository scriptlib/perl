#!/usr/bin/env perl 
# $Id$
#===============================================================================
#         NAME: run_progress
#  DESCRIPTION: 
#       AUTHOR: xiaoranzzz <xiaoranzzz@MyPlace>
# ORGANIZATION: MyPlace HEL ORG.
#      VERSION: 1.0
#      CREATED: 2016-06-02 00:00
#     REVISION: ---
#===============================================================================
package MyPlace::Script::run_progress;
use strict;

our $VERSION = 'v0.1';
my @OPTIONS = qw/
	help|h|? 
	manual|man
/;

my $COUNT = 0;
my @LINES;
while(<STDIN>) {
	chomp;
	push @LINES,$_;
	$COUNT++;
}
if($COUNT<1) {
	print STDERR "No input from STDIN\n";
	exit 0;
}
if(!@ARGV) {
	push @ARGV,"echo";
}

my $INDEX = 1;
my @args = @ARGV;
while($INDEX<=$COUNT) {
	print STDERR "[$INDEX/$COUNT] ",join(" ",@args,$LINES[$INDEX-1]),"\n";
	open FO,"|-",'xargs','-l',@args;
	print FO $LINES[$INDEX-1],"\n";
	close FO;
	$INDEX++;
}

__END__

=pod

=head1  NAME

run_progress - PERL script

=head1  SYNOPSIS

run_progress [options] ...

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

    2016-06-02 00:00  xiaoranzzz  <xiaoranzzz@MyPlace>
        
        * file created.

=head1  AUTHOR

xiaoranzzz <xiaoranzzz@MyPlace>

=cut

#       vim:filetype=perl
