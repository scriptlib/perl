#!/usr/bin/env perl 
# $Id$
#===============================================================================
#         NAME: md5sum
#  DESCRIPTION: 
#       AUTHOR: xiaoranzzz <xiaoranzzz@MyPlace>
# ORGANIZATION: MyPlace HEL ORG.
#      VERSION: 1.0
#      CREATED: 2016-04-27 02:06
#     REVISION: ---
#===============================================================================
package MyPlace::Script::md5sum;
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
my $text = join("",<>);
use Encode qw/encode_utf8/;
use Encode;
$text = encode_utf8($text);
use Digest::MD5 qw/md5_hex md5/;
print STDERR md5_hex($text),"\n";


__END__

=pod

=head1  NAME

md5sum - PERL script

=head1  SYNOPSIS

md5sum [options] ...

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

    2016-04-27 02:06  xiaoranzzz  <xiaoranzzz@MyPlace>
        
        * file created.

=head1  AUTHOR

xiaoranzzz <xiaoranzzz@MyPlace>

=cut

#       vim:filetype=perl
#!/usr/bin/env perl 
#===============================================================================
#
#         FILE: md5sum.pl
#
#        USAGE: ./md5sum.pl  
#
#  DESCRIPTION: 
#
#      OPTIONS: ---
# REQUIREMENTS: ---
#         BUGS: ---
#        NOTES: ---
#       AUTHOR: Eotect Nahn (eotect), eotect@myplace.hel
# ORGANIZATION: MyPlace HEL. ORG.
#      VERSION: 1.0
#      CREATED: 2016/04/27  2:06:56
#     REVISION: ---
#===============================================================================

use strict;
use warnings;
use utf8;

