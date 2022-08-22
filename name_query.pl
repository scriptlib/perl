#!/usr/bin/perl 
# $Id$
#===============================================================================
#         NAME: name_query
#  DESCRIPTION: 
#       AUTHOR: xiaoranzzz <xiaoranzzz@MyPlace>
# ORGANIZATION: MyPlace HEL ORG.
#      VERSION: 1.0
#      CREATED: 2021-11-08 00:12
#     REVISION: ---
#===============================================================================
package MyPlace::Script::name_query;
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
else {
	$OPTS{'help'} = 1;
}
if($OPTS{'help'} or $OPTS{'manual'}) {
	require Pod::Usage;
	my $v = $OPTS{'help'} ? 1 : 2;
	Pod::Usage::pod2usage(-exitval=>$v,-verbose=>$v);
    exit $v;
}


my @DIRS = ('.','database','download','todo','trash');
my @RULES = ('avstars','babes','videos','beauty','tags');

sub find_dir {
	my $exp = shift;
	my $dir = shift;
	my $depth = shift;
	my @r;
	my @n;
	if($depth > 0) {
		if(-f "$dir/names.txt" and open FI,"<","$dir/names.txt") {
			foreach(<FI>) {
				chomp;
				if(m/$exp/) {
					push @r,"$dir/names.txt";
				}
			}
			close FI;
		}
		opendir(my $DI,$dir);
		foreach(readdir($DI)) {
			next if(m/^\.+$/);
			my $sd = "$dir/$_";
			next unless(-d $sd);
			#	print STDERR "$sd\n";
			if(m/$exp/) {
				push @r,$sd;
			}
			else {
				push @n,$sd;
			}
		}
		close $DI;
		$depth--;
		if($depth > 0) {
			foreach(@n) {
				push @r,find_dir($exp,$_,$depth);
			}
		}
	}
	return @r;
}

sub find_rule {
	my $exp = shift;
	my $rule = shift;
	my $file = shift;
	if(system('r-config','-f',$file,'query',"/$exp/") == 0) {
		print("--> Found in RULE [$rule]\n");
	}
}
my $exp = shift;
die("Usage: $0 name\n") unless($exp);
foreach(@DIRS) {
	foreach(find_dir($exp,$_,3)) {
		print "$exp\n--> Found in DIRECTORY [$_]\n";
	}
}
foreach(@RULES) {
	find_rule($exp,$_,$ENV{HOME} . "/.classify/" . $_ . ".rule");
	find_rule($exp,$_,".classify/" . $_ . ".rule");
}
__END__

=pod

=head1  NAME

name_query - PERL script

=head1  SYNOPSIS

name_query [options] ...

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

    2021-11-08 00:12  xiaoranzzz  <xiaoranzzz@MyPlace>
        
        * file created.

=head1  AUTHOR

xiaoranzzz <xiaoranzzz@MyPlace>

=cut

#       vim:filetype=perl
