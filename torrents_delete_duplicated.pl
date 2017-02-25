#!/usr/bin/env perl 
# $Id$
#===============================================================================
#         NAME: torrents_delete_duplicated
#  DESCRIPTION: 
#       AUTHOR: xiaoranzzz <xiaoranzzz@MyPlace>
# ORGANIZATION: MyPlace HEL ORG.
#      VERSION: 1.0
#      CREATED: 2016-11-05 04:22
#     REVISION: ---
#===============================================================================
package MyPlace::Script::torrents_delete_duplicated;
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

my @DELETE;
my @REMAIN;
my %KEEP;
my %DUP;
while(<>) {
	chomp;
	if($_ =~ m/^(.+)_([A-Fa-f0-9]{40})\.(?:MASKED.torrent|torrent|txt)$/) {
		my $basename = $1;
		my $hash = $2;
		my $suffix = $3;
		if($DUP{$hash} and $KEEP{$basename}) {
			push @REMAIN,$_;
			next;
		}
		elsif($DUP{$hash}) {
			push @DELETE,$_;
		}
		else {
			$DUP{$hash} = 1;
			$KEEP{$basename} = 1;
			push @REMAIN,$_;
		}
	}
}

print STDERR '='x40,"\n";
foreach(@REMAIN) {
	print STDERR "+ $_","\n";
}
print STDERR '='x40,"\n";
print STDERR "Above files will remain\n";
print STDERR '='x40,"\n";
foreach(@DELETE) {
	print STDERR "- $_","\n";
}
print STDERR '='x40,"\n";
print STDERR "Above files will be deleted\n";
print STDERR '='x40,"\n";
#unlink @DELETE;
print STDERR "Summary:\n";
print STDERR "Files remain:  " . scalar(@REMAIN) . "\n";
print STDERR "Files deleted: " . scalar(@DELETE) . "\n";
print STDERR '='x40,"\n";


__END__

=pod

=head1  NAME

torrents_delete_duplicated - PERL script

=head1  SYNOPSIS

torrents_delete_duplicated [options] ...

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

    2016-11-05 04:22  xiaoranzzz  <xiaoranzzz@MyPlace>
        
        * file created.

=head1  AUTHOR

xiaoranzzz <xiaoranzzz@MyPlace>

=cut

#       vim:filetype=perl
