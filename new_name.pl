#!/usr/bin/perl 
# $Id$
#===============================================================================
#         NAME: new_name
#  DESCRIPTION: create a directory based on names
#       AUTHOR: xiaoranzzz <xiaoranzzz@MYPLACE>
# ORGANIZATION: MyPlace HEL ORG.
#      VERSION: 1.0
#      CREATED: 2019-12-12 03:18
#     REVISION: ---
#===============================================================================

package MyPlace::Script::new_name;
use strict;
use warnings;
use utf8;

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

my $cat = shift;
my $data = shift;
if(!$data) {
	$data = $cat;
	$cat = undef;
}

if((!$cat) and ($OPTS{rule})) {
	$cat = $OPTS{rule} if(-d $OPTS{rule});
}

my @data = split(/\s*,\s*/,$data);
my $name = shift(@data);
my $pdir = $cat ? "$cat/$name" : "$name";
my %dups;

system("mkdir","-p","-v","--",$pdir) unless(-d $pdir);

if(open FI,"<","$pdir/names.txt") {
	$dups{$_} = 1 foreach(<FI>);
	close FI;
}

print STDERR "Writting <$pdir/names.txt> ...";
open FO,">>","$pdir/names.txt" or die("\n$!\n");

my $prefix = $OPTS{rule} ? $OPTS{rule} . ":" : "";

my $count = 0;
foreach($name,@data) {
	if($OPTS{rule} and ($OPTS{rule} eq 'avstar') or ($OPTS{rule} eq 'pornstar')) {
		if(m/^[\w\s_-]+$/) {
			$prefix = "porn:";
		}
		else {
			$prefix = "jav|cn:";
		}
	}
	my $line = $prefix . $_ . "\n";
	next if($dups{$line});
	$count++;
	print FO $line;
	print STDERR "\n    ",$line;
}
close FO;
if($count>0) {
	print STDERR "  [OK]\n";
}
else {
	print STDERR "  [Nothing changed]\n";
}
print STDERR "\n";
use File::Spec::Functions qw/catfile/;
#RULE

#rule file:
#1. "A.rule"
#2. "A/rule"
#3. "A/.rule"
#3. "A/A.rule"

#4. "DIR/A"
#5. "DIR/A.rule"
#4. "rules/A.rule"
#5. "classify/A.rule"
#6. ".rules/A.rule"
#7. ".classify/A.rule"
#rule dir:
#1. "."
#2. "rules"
#3. "classify"
#4. ".rules"
#5. ".classify"
if($OPTS{rule}) {
	my $rule_dir;
	my $rule_file;
	foreach my $pdir(".",$ENV{HOME}) {
		foreach my $pre("","rules","classify",".rules",".classify") {
			foreach my $pre2(".","/","/.","/$OPTS{rule}.") {
				foreach my $suf("rule","rules") {
					my $t = catfile($pdir,$pre,$OPTS{rule} . $pre2 . $suf);
					if(-f $t) {
						$rule_file = $t;
						last;
					}
				}
			}
		}
	}
	if(!$rule_file) {
		foreach my $prefix(".",$ENV{HOME}) {
			foreach("classify",".classify","rules",".rules") {
				if(-d catfile($prefix,$_)) {
					$rule_dir = catfile($prefix,$_);
					last;
				}
			}
			last if($rule_dir);
		}
		$rule_dir = catfile($ENV{HOME},".classify") unless($rule_dir);
		if(!-d $rule_dir) {
			system(qw/mkdir -p -v --/,$rule_dir);
		}
		if(!-d $rule_dir) {
			print STDERR "Error creating directory $rule_dir\n!";
			exit 1;
		}
		$rule_file = catfile($rule_dir,$OPTS{rule} . ".rule");
	}
	system("confa","-f",$rule_file,"--","add",$name,@data);
}


__END__

=pod

=head1  NAME

new_name - PERL script

=head1  SYNOPSIS

new_name [options] ...

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

    2019-12-12 03:18  xiaoranzzz  <xiaoranzzz@MYPLACE>
        
        * file created.

=head1  AUTHOR

xiaoranzzz <xiaoranzzz@MYPLACE>

=cut

#       vim:filetype=perl
