#!/usr/bin/env perl 
# $Id$
#===============================================================================
#         NAME: grepfiles
#  DESCRIPTION: Grep files based on files status
#       AUTHOR: xiaoranzzz <xiaoranzzz@MyPlace>
# ORGANIZATION: MyPlace HEL ORG.
#      VERSION: 1.0
#      CREATED: 2018-10-15 02:19
#     REVISION: ---
#===============================================================================
package MyPlace::Script::grepfiles;
use strict;

our $VERSION = 'v0.1';
my @OPTIONS = qw/
	help|h|? 
	manual|man
	lessthan|lt=i
	morethan|mt=i
	equal|eq=i
	exp|e=s
	depth|d=i
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

use File::Glob qw/bsd_glob/;

sub test_lessthan {
	my $fs = shift;
	my $max = shift;
	my $exp = shift;
	my $depth = shift;
	$exp = "*" unless($exp);
	$depth = 0 unless($depth);
	if($max < 0) {
		return undef,0;
	}
	if(! -d $fs) {
		print STDERR "\t" x $depth . " $fs: 1 file itself.\n";
		if($max >1) {
			return 1,1;
		}
		else {
			return undef,1;
		}
	}
	my @dirs;
	my $files = 0;
	foreach(bsd_glob("$fs/$exp")) {
		next if(m/^\/\.+$/);
		$files++;
		push @dirs,$_ if(-d $_);
	}
	print STDERR "\t" x $depth . " $fs/$exp: get $files files.\n";
	if($files >= $max) {
		return undef,$files;
	}
	if($OPTS{depth} and $depth>$OPTS{depth}) {
		return undef,$files;
	}
	foreach(@dirs) {
		my $nd = $_;
		my $nm = $max - $files;
		my $nt = $depth + 1;
		my($ok,$count) = test_lessthan($nd,$nm,$exp,$nt);
		if(!$ok) {
			return undef,$files+$count;
		}
		$files = $files + $count;
		if($files >= $max) {
			return undef,$files;
		}
	}
	return 1,$files;
}

my @target = @ARGV;
if(!@target) {
	print STDERR "No files to test\n";
	exit 1;
}
foreach(@target) {
	my $ok;
	my $count;
	if(defined $OPTS{lessthan}) {
		($ok,$count) = test_lessthan($_,$OPTS{lessthan},$OPTS{exp});
	}
	elsif(defined $OPTS{morethan}) {
		($ok,$count) = test_morethan($_,$OPTS{morethan},$OPTS{exp});
	}
	elsif(defined $OPTS{equal}) {
		($ok,$count) = test_equal($_,$OPTS{equal},$OPTS{exp});
	}
	else {
		$ok = 1;
		$count = "unknown";
	}
	if($ok) {
		print $_,"\n";
		print STDERR "\t $count files count [GOOD]\n";
	}
	else {
		print STDERR "\t$_ $count files count [BAD]\n";
	}
}



__END__

=pod

=head1  NAME

grepfiles - PERL script

=head1  SYNOPSIS

grepfiles [options] ...

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

    2018-10-15 02:19  xiaoranzzz  <xiaoranzzz@MyPlace>
        
        * file created.

=head1  AUTHOR

xiaoranzzz <xiaoranzzz@MyPlace>

=cut

#       vim:filetype=perl
