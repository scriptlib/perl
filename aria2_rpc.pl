#!/usr/bin/perl 
# $Id$
#===============================================================================
#         NAME: aria2_rpc
#  DESCRIPTION: 
#       AUTHOR: xiaoranzzz <xiaoranzzz@MyPlace>
# ORGANIZATION: MyPlace HEL ORG.
#      VERSION: 1.0
#      CREATED: 2021-02-01 05:29
#     REVISION: ---
#===============================================================================
package MyPlace::Script::aria2_rpc;
use strict;

our $VERSION = 'v0.1';
my @OPTIONS = qw/
	help|h|? 
	manual|man
	url:s
	load-cookies|cookie:s
	save-cookies|cookie-jar:s
	out|output:s
	http-accept-gzip|compressed
	max-time:i
	connect-timeout:i
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
use MyPlace::Program;
use LWP::UserAgent;
use JSON;
use Data::Dumper;
use Cwd qw/getcwd/;
use Encode qw/find_encoding/;
my $utf8 = find_encoding('utf-8');

my $json = JSON->new->allow_nonref->utf8;
my $ua = LWP::UserAgent->new();
my $url = $OPTS{url};
foreach(qw/max-time connect-timeout url/) {
	delete $OPTS{$_};
}
my %params = %OPTS;
$params{dir} = getcwd;
$params{dir} = `cygpath -w "$params{dir}"`;
chomp $params{dir};


my %content = (
	'jsonrpc'	=>	'2.0',
	'id'		=>	'aria2_rpc_perl',
	'method'	=>	'aria2.addUri',
	'params'	=>	[[$url],\%params],
);


my $d = $ua->post('http://localhost:6800/jsonrpc',
	Content_Type	=>	'application/json',
	Accept			=>	'application/json',
	Content			=>	$utf8->decode($json->encode(\%content)),
);
#print Data::Dumper->Dump([$d],['response']);
if(!$d->is_success) {
	print STDERR "[ARIA2_RPC] ",$d->status_line,"\n";
	exit 1;
}
print STDERR "[ARIA2_RPC] ",$d->status_line,"\n";
my $r = $json->decode($d->content);

if($r->{error}) {
	print STDERR "[ARIA2_RPC] ",$r->{error}->{code}," ",$r->{error}->{message},"\n";
	exit $r->{error}->{code};
}
print STDERR "[ARIA2_RPC] ",$d->content,"\n";
exit MyPlace::Program::EXIT_CODE("PASS");



__END__

=pod

=head1  NAME

aria2_rpc - PERL script

=head1  SYNOPSIS

aria2_rpc [options] ...

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

    2021-02-01 05:29  xiaoranzzz  <xiaoranzzz@MyPlace>
        
        * file created.

=head1  AUTHOR

xiaoranzzz <xiaoranzzz@MyPlace>

=cut

#       vim:filetype=perl
