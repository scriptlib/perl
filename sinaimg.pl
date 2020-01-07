#!/usr/bin/perl 
# $Id$
#===============================================================================
#         NAME: sinaimg
#  DESCRIPTION: 
#       AUTHOR: xiaoranzzz <xiaoranzzz@MYPLACE>
# ORGANIZATION: MyPlace HEL ORG.
#      VERSION: 1.0
#      CREATED: 2019-12-22 00:47
#     REVISION: ---
#===============================================================================
package MyPlace::Script::sinaimg;
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

foreach(@ARGV) {
	if(m/([\da-zA-Z]{32}).*\.([^\.]+)$/) {
		my $id = $1;
		my $ext = $2;
		my $filename = $_;
		$filename =~ s/.*\///;
		my $rename = $filename;
		$rename =~ s/\.([^\.]+)$/.bak.$1/;
		rename $_,$rename;
		system("download","http://ww4.sinaimg.cn/large/$id.$ext","-s",$filename);
	}
}


__END__

=pod

=head1  NAME

sinaimg - PERL script

=head1  SYNOPSIS

sinaimg [options] ...

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

    2019-12-22 00:47  xiaoranzzz  <xiaoranzzz@MYPLACE>
        
        * file created.

=head1  AUTHOR

xiaoranzzz <xiaoranzzz@MYPLACE>

=cut

#       vim:filetype=perl
