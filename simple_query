#!/usr/bin/perl -w
# $Id$
package MyPlace::Script::simple_query;
use strict;

our $VERSION = 'v0.1';
my @OPTIONS = qw/
	help|h|? 
	manual|man
	database|db|file|f=s
	add|a
	query|q
	dump|d
	command|c=s
	additem
	overwrite
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

use MyPlace::SimpleQuery;

my $action = $OPTS{command};
if(!$action) {
	if($OPTS{add}) {
		$action = 'ADD';
	}
	elsif($OPTS{query}) {
		$action = 'QUERY';
	}
	elsif($OPTS{dump}) {
		$action = 'DUMP';
	}
	elsif($OPTS{additem}) {
		$action = 'ADDITEM';
	}
}
else {
	$action = uc($action);
}
$action = uc(shift(@ARGV)) unless($action);

if($action !~ /^(?:ADD|QUERY|DUMP|ADDITEM)$/) {
	print STDERR "Error action <$action> not supported\n";
	exit 1;
}


my $sq = new MyPlace::SimpleQuery;
$sq->set_options('overwrite',1) if($OPTS{overwrite});
my $data = $OPTS{database};
if(!$data) {
	print STDERR "Read data from stdin: \n";
	$data=join("",<STDIN>);
}
$sq->feed($data,'file');

my $status = 1;
my @query = @ARGV;
my @targets;
if($action eq 'ADD') {
	($status,@targets) = $sq->add(@query);
	if($status) {
		print STDERR "$status item(s) add to database\n";
		if($data) {
			$sq->saveTo($data);
		}
	}
	else {
		print STDERR "Error: ",join(" ",@targets),"\n";
		exit 2;
	}
	
}
elsif($action eq 'ADDITEM') {
	($status,@targets) = $sq->additem(@query);
	if($status) {
		print STDERR "Item add to database\n";
		if($data) {
			$sq->saveTo($data);
		}
	}
	else {
		print STDERR "Error: ",join(" ",@targets),"\n";
		exit 2;
	}
}
else {
	($status,@targets) = $sq->query(@query);
	if(!$status) {
		print STDERR "Query error.\n";
		print STDERR join("\n",@targets),"\n" if(@targets);
		exit 3;
	}
	if($action eq 'QUERY') {
		print "QUERY: ", join(", ",@query),"\n";
		foreach my $item (@targets) {
			print join("\n\t",@$item),"\n";
		}
	}
	elsif($action eq 'DUMP') {
		print "DUMP: ", join(", ",@query),"\n";
		use Data::Dumper;
		print Data::Dumper->Dump([\@targets],['@Result']);
	}
}







__END__

=pod

=head1  NAME

simple_query - PERL script

=head1  SYNOPSIS

simple_query [options] ...

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

    2014-09-11 23:26  xiaoranzzz  <xiaoranzzz@MyPlace>
        
        * file created.

=head1  AUTHOR

xiaoranzzz <xiaoranzzz@MyPlace>

=cut

#       vim:filetype=perl
