#!/usr/bin/perl 
# $Id$
#===============================================================================
#         NAME: find_name_by_rule
#  DESCRIPTION: 
#       AUTHOR: xiaoranzzz <xiaoranzzz@MyPlace>
# ORGANIZATION: MyPlace HEL ORG.
#      VERSION: 1.0
#      CREATED: 2022-07-07 01:20
#     REVISION: ---
#===============================================================================
package MyPlace::Script::find_name_by_rule;
use strict;

our $VERSION = 'v0.1';
my @OPTIONS = qw/
	help|h|? 
	manual|man
	rule|r=s
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
use MyPlace::Config::Array;

my $catalog = $OPTS{rule} || "avstars,fuckher,babes,pornstars,actress,babes,sluts,camgirls,posters";


my @SELECT = split(/\s*,\s*/,$catalog);
if(0 and (!@ARGV)) {
	my $pname = $0;
	$pname =~ s/.*[\/\\]+//;
	print STDERR "find_avstar v1.0\n";
	print STDERR "  This program will try to figure out\n";
	print STDERR "directory for specified names in hand\n";
	print STDERR "coded directories:\n";
	print STDERR "  $_\n" foreach(@SELECT);
	print STDERR "Usage:\n";
	print STDERR "    $pname [--suggest] [name1,name2] [name3,name4]\n";
	exit 1;
}

foreach(@ARGV) {
	next unless($_);
	foreach my $n (split(/\s*,.*/,$_)) {
		foreach(@SELECT) {
			my $rule = `find_rule.pl "$_"`;
			chomp($rule);
			if(-f $rule) {
				my $confa = MyPlace::Config::Array->new();
				$confa->readfile($rule);
				my @data = $confa->get($n);
				if(@data and $#data) {
					print "$n\n[$rule]\n  ",join("\n  ",@data),"\n";
				}
			}
		}
	}
}



__END__

=pod

=head1  NAME

find_name_by_rule - find directory for names under specified catalog

=head1  SYNOPSIS

find_name_by_rule [options] <catalog> <name>

=head1  OPTIONS

=over 12

=item B<--suggest>

Suggest directory avaiable

=item B<--catalog>

Specify catalog to search

=item B<--append>

Append directies to searching list

=item B<--cwd>

Append current working directory to searching list

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

    2022-07-07 01:20  xiaoranzzz  <xiaoranzzz@MyPlace>
        
        * file created.

=head1  AUTHOR

xiaoranzzz <xiaoranzzz@MyPlace>

=cut

#       vim:filetype=perl
