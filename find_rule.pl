#!/usr/bin/perl 
# $Id$
#===============================================================================
#         NAME: find_rule
#  DESCRIPTION: create a directory based on names
#       AUTHOR: xiaoranzzz <xiaoranzzz@MYPLACE>
# ORGANIZATION: MyPlace HEL ORG.
#      VERSION: 1.0
#      CREATED: 2019-12-12 03:18
#     REVISION: ---
#===============================================================================

package MyPlace::Script::find_rule;
use strict;
use warnings;
use utf8;

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

my $cat = shift;

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
if($cat) {
	my $rule_dir;
	my $rule_file;
	foreach my $pdir(".",$ENV{HOME}) {
		foreach my $pre("","rules","classify",".rules",".classify") {
			foreach my $pre2(".","/","/.","/${cat}.") {
				foreach my $suf("rule","rules") {
					my $t = catfile($pdir,$pre,${cat} . $pre2 . $suf);
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
		$rule_file = catfile($rule_dir,${cat} . ".rule");
	}
	print $rule_file,"\n";
}


__END__

=pod

=head1  NAME

find_rule - PERL script

=head1  SYNOPSIS

find_rule [options] ...

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
