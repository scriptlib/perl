#!/usr/bin/perl 
# $Id$
#===============================================================================
#         NAME: find_name
#  DESCRIPTION: 
#       AUTHOR: xiaoranzzz <xiaoranzzz@MyPlace>
# ORGANIZATION: MyPlace HEL ORG.
#      VERSION: 1.0
#      CREATED: 2022-07-07 01:20
#     REVISION: ---
#===============================================================================
package MyPlace::Script::find_name;
use strict;

our $VERSION = 'v0.1';
my @OPTIONS = qw/
	help|h|? 
	manual|man
	suggest|s
	catalog|c=s
	cwd=s
	append=s
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

my $catalog = $OPTS{catalog} || "avstars,fuckher,babes,ladies,pornstars,actress,babes,sluts,camgirls,capture,douyin,posters";


my @SELECT;
foreach my $c(split(/\s*,\s*/,$catalog)) {
	push @SELECT,(
		"$c",
		"todo/$c",
		"/myplace/.x/todo/$c",
		"/datapool/g/todo/$c",
		"/datapool/f/todo/$c",
		"/datapool/e/todo/$c",
		"/myplace/.x/$c",
		"/datapool/g/$c",
		"/datapool/f/$c",
		"/datapool/e/$c",
	);
}

push @SELECT,split(/\s*|\s*/,$OPTS{append}) if($OPTS{append});
push @SELECT,"." if($OPTS{cwd});
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

sub select_target {
	my $n = shift;
	my @first;
	foreach(@SELECT) {
		push @first,$_ if(-d $_);
	}
	if($n) {
		foreach(@first) {
			if(-d "$_/$n") {
				print STDERR "[$_/$n]\n";
				return $_;
			}
		}
	}
	if($OPTS{suggest}) {
		my $d = shift(@first);
		if($d) {
			print STDERR "Suggest: [$d/$n]\n";
			return $d;
		}
	}
}

use Cwd qw/getcwd/;
my $cwd = getcwd;
foreach(@ARGV) {
	next unless($_);
	foreach my $n (split(/\s*,.*/,$_)) {
		my $target_dir = select_target($n);
		print $target_dir,"\n" if($target_dir);
		if($OPTS{rule}) {
			system('find_name_by_rule.pl','-r',$OPTS{rule},$n);
		}
	}
}



__END__

=pod

=head1  NAME

find_name - find directory for names under specified catalog

=head1  SYNOPSIS

find_name [options] <catalog> <name>

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

=item B<--rule>

Also search by rule files

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
