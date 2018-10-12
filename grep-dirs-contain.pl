#!/usr/bin/env perl 
# $Id$
#===============================================================================
#         NAME: grep-dirs-contain
#  DESCRIPTION: 
#       AUTHOR: xiaoranzzz <xiaoranzzz@MyPlace>
# ORGANIZATION: MyPlace HEL ORG.
#      VERSION: 1.0
#      CREATED: 2018-07-17 03:45
#     REVISION: ---
#===============================================================================
package MyPlace::Script::grep_dirs_contain;
use strict;

our $VERSION = 'v0.1';
my @OPTIONS = qw/
	help|h|? 
	manual|man
	invert|i
/;
my %OPTS;
if(@ARGV)
{
    require Getopt::Long;
	#Getopt::Long::Configure('pass_through',1);
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

sub process {
	my $dir = shift;
	my $exp = shift;
	my @dirs;
	opendir my $FI,$dir;
	foreach(readdir($FI)) {
		#print STDERR "$dir: $_\n";
		if(m/$exp/) {
			close $FI;
			return 1;
		}
		next if(m/^\.+$/);
		if(-d "$dir/$_") {
			push @dirs,"$dir/$_";
		}
	}
	close $FI;
	foreach(@dirs) {
		return 1 if(process($_,$exp));
	}
	return undef;
}

my $exp = shift;
foreach(@ARGV) {
	if(!-d $_) {
		print STDERR "\"$_\" no directory [IGNORED]\n";
		next;
	}
	my $r = process($_,$exp);
	if($OPTS{invert}) {
		$r = not $r;
	}
	print $_,"\n" if($r);
}


__END__

=pod

=head1  NAME

grep-dirs-contain - PERL script

=head1  SYNOPSIS

grep-dirs-contain [options] ...

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

    2018-07-17 03:45  xiaoranzzz  <xiaoranzzz@MyPlace>
        
        * file created.

=head1  AUTHOR

xiaoranzzz <xiaoranzzz@MyPlace>

=cut

#       vim:filetype=perl
