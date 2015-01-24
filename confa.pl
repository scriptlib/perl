#!/usr/bin/perl -w
# $Id$
package MyPlace::Script::confa;
use warnings;
use strict;
use MyPlace::Config::Array;

our $VERSION = 'v0.1';
my @OPTIONS = qw/
	help|h|? 
	manual|man
	sort|s
	filename|f:s
	dump|d
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

my $A = MyPlace::Config::Array->new();
if($OPTS{filename}) {
	$A->readfile($OPTS{filename});
}
elsif(@ARGV and -f $ARGV[0]) {
	$OPTS{filename} = shift @ARGV;
	$A->readfile($OPTS{filename});
}
else {
	$A->readtext(<STDIN>);
}

my $action;
if(!@ARGV) {
	$action = 'LIST';
}
else {
	$action = uc(shift(@ARGV));
}

if($action eq 'LIST') {
	$A->sort() if($OPTS{sort});
	print $A->get_text();
	exit 0;
}
elsif($action eq 'DUMP') {
	$A->sort() if($OPTS{sort});
	print $A->dump;
	exit 0;
}
elsif($action eq "ADD") {
	if(@ARGV) {
		$A->add(@ARGV);
	}
	else {
		print STDERR "Usage: $0 add key [values...]\n";
		exit 1;
	}
}
elsif($action eq "SET") {
	if(@ARGV) {
		$A->set(@ARGV);
	}
	else {
		print STDERR "Usage: $0 set key [values...]\n";
		exit 1;
	}
}
elsif($action eq 'RM' or $action eq 'DELETE') {
	if(@ARGV) {
		$A->delete(@ARGV);
	}
	else {
		print STDERR "Usage: $0 rm|delete keys...\n";
		exit 1;
	}
}
elsif($action eq 'SORT') {
	$OPTS{sort} = 1;
}
elsif($action eq 'WRITE') {
}
else {
	print STDERR "Error invalid action : $action!\n";
	exit 2;
}
$A->sort() if($OPTS{sort});
$A->writefile() if($A->isdirty() or $action eq 'WRITE');
$A->dump() if($OPTS{dump});

__END__

=pod

=head1  NAME

confa - PERL script

=head1  SYNOPSIS

confa [options] ...

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

    2014-11-23 01:26  xiaoranzzz  <xiaoranzzz@MyPlace>
        
        * file created.

=head1  AUTHOR

xiaoranzzz <xiaoranzzz@MyPlace>

=cut

#       vim:filetype=perl
