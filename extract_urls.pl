#!/usr/bin/env perl 
# $Id$
#===============================================================================
#         NAME: extract_urls
#  DESCRIPTION: 
#       AUTHOR: xiaoranzzz <xiaoranzzz@MyPlace>
# ORGANIZATION: MyPlace HEL ORG.
#      VERSION: 1.0
#      CREATED: 2016-05-08 02:39
#     REVISION: ---
#===============================================================================
package MyPlace::Script::extract_urls;
use strict;

our $VERSION = 'v0.1';
my @OPTIONS = qw/
	help|h|? 
	manual|man
	type|t|proto|p=s
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
sub js_unescape {
	if(!@_) {
		return;
	}
	elsif(@_ == 1) {
		local $_ = $_[0];
		s/&amp;amp;/&/g;
		s/&amp;/&/g;
        $_ =~ s/%u([0-9a-f]+)/chr(hex($1))/eig;
        $_ =~ s/%([0-9a-f]{2})/chr(hex($1))/eig;
		return $_;
	}
	else {
		my @r;
		local $_;
		foreach(@_) {
			$_ = js_unescape($_);
			push @r,$_;
	    }
		return @r;
	}
}

my @match;
my %dup;
while(<>) {
	chomp;
	while(m/"(\w+:[^"]+)"/g) {
		push @match,$1 unless($dup{$1});
		$dup{$1} = 1;
	}
	while(m/((?:http|ftp|magnet|ed2k|qvod|bdhd|thunder):[^"'\s]+)/g) {
		push @match,$1 unless($dup{$1});
		$dup{$1} = 1;
	}
}
my @urls;
my $exp = qr/^$OPTS{'type'}:/ if($OPTS{'type'});
foreach(@match) {
	next if($exp and ($_ !~ m/$exp/));
	push @urls,js_unescape($_);
}


print join("\n",@urls),"\n";


__END__

=pod

=head1  NAME

extract_urls - PERL script

=head1  SYNOPSIS

extract_urls [options] ...

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

    2016-05-08 02:39  xiaoranzzz  <xiaoranzzz@MyPlace>
        
        * file created.

=head1  AUTHOR

xiaoranzzz <xiaoranzzz@MyPlace>

=cut

#       vim:filetype=perl
