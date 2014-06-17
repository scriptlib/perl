#!/usr/bin/perl -w
# $Id$
package MyPlace::Script::gettorrent_title;
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

sub gethtml {
	my $URL = shift;
	my $REF = shift(@_) || $URL;
	my @cmd = (
		qw{curl --fail --silent -L -A Mozilla/5.0 -m 180 --connect-timeout 15},
		"--referer",$REF,
		'--url',$URL,
	);
	open FI,'-|',@cmd or die("$!\n");
	my $text= join("",<FI>);
	close FI;
	return $text;
}

my $hash = shift;
my $url = "http://bitsnoop.com/search/all/$hash/c/d/1/";
print STDERR "Retriving info from $url\n";
my $html = gethtml($url);
if($html =~ m/<title>\s*([^<]+?)\s+- Video - Torrent Download \| Bitsnoop</) {
	print $1;
}

__END__

=pod

=head1  NAME

gettorrent_title - PERL script

=head1  SYNOPSIS

gettorrent_title [options] ...

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

    2014-06-18 01:00  xiaoranzzz  <xiaoranzzz@MyPlace>
        
        * file created.

=head1  AUTHOR

xiaoranzzz <xiaoranzzz@MyPlace>

=cut

#       vim:filetype=perl
