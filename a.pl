#!/usr/bin/perl -w
# $Id$
use strict;
require v5.10.0;
our $VERSION = 'v0.1';

BEGIN
{
    my $PROGRAM_DIR = $0;
    $PROGRAM_DIR =~ s/[^\/\\]+$//;
    $PROGRAM_DIR = "./" unless($PROGRAM_DIR);
    unshift @INC, 
        map "$PROGRAM_DIR$_",qw{modules lib ../modules ..lib};
}

my %OPTS;
my @OPTIONS = qw/help|h|? version|ver edit-me manual|man/;

if(@ARGV)
{
    require Getopt::Long;
    require MyPlace::Usage;
    Getopt::Long::GetOptions(\%OPTS,@OPTIONS);
    MyPlace::Usage::Process(\%OPTS,$VERSION);
}
else
{
    require MyPlace::Usage;
    MyPlace::Usage::PrintHelp();
}


__END__

=pod

=head1  NAME

___NAME___ - PERL script

=head1  SYNOPSIS

___NAME___ [options] ...

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

    2010-08-15 21:10:05  xiaoranzzz  <___EMAIL___>
        
        * file created.

=head1  AUTHOR

xiaoranzzz <___EMAIL___>

=cut



