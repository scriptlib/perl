#!/usr/bin/env perl 
# $Id$
#===============================================================================
#         NAME: urilst_clean
#  DESCRIPTION: 
#       AUTHOR: xiaoranzzz <xiaoranzzz@MyPlace>
# ORGANIZATION: MyPlace HEL ORG.
#      VERSION: 1.0
#      CREATED: 2016-04-19 03:21
#     REVISION: ---
#===============================================================================
package MyPlace::Script::urilst_clean;
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

my %dup;
my $EMPTY = '[_\s－——]*';
my $dup = 0;
my $count = 0;
while(<>) {
	chomp;
	my $id;
	next if(m/^qvod:\/\/0\|/);
	if(m/^(qvod:\/\/[^\|]+\|([^\|]+)\|)(.+)$/) {
		my $prefix = $1;
		$id = $2;
		my $filename = $3;
		$filename =~	s/$EMPTY(?:\[[^\]]+\]|☆快播室★qvod8.info☆|快播室|日韩|情色中国|爱播成人网aibbb\.com|www\.[^\.}+\.com|www\.[^\.]+\.net|97so_cn|本色吧影院|\(|观看更多请到|观看更多|[^\.]+\.com|[^\.]+\.net|qvod|6A电影|ADY电影|美国色吧|[^\.]+\.us|看更多到|rihan|sdycom|ADY電影)$EMPTY//ig;
		$filename =~ s/${EMPTY}www\.[^\.]+\.(?:com|net|us)$EMPTY//gi;
		$filename =~ s/^${EMPTY}(?:[\d\]\[\)\(\@]+|AV|Media|[A-Z]_|www\.)${EMPTY}//gi;
		if($filename =~ m/^\.?([^\.]+)$/) {
			$filename = "NONAME." . $1;
		}
		$_ = $prefix . $filename;
	}
	else {
		next;
	}
	if($dup{$id}) {
		$dup++;
		next;
	}
	$dup{$id} = 1;
	print $_,"\n";
	$count++;
}
print STDERR "  $dup items duplicated\n$count items remain\n";

__END__

=pod

=head1  NAME

urilst_clean - PERL script

=head1  SYNOPSIS

urilst_clean [options] ...

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

    2016-04-19 03:21  xiaoranzzz  <xiaoranzzz@MyPlace>
        
        * file created.

=head1  AUTHOR

xiaoranzzz <xiaoranzzz@MyPlace>

=cut

#       vim:filetype=perl
