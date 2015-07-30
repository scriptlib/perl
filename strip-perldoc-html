#!/usr/bin/perl -w
# $Id$
package MyPlace::Script::strip_perldoc_html;
use strict;

our $VERSION = 'v0.1';
my @OPTIONS = qw/
	help|h|? 
	manual|man
	inplace|i
	output|o=s
	source|s=s
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


my $source = $OPTS{source} || shift(@ARGV);
my $output = $OPTS{output} || ($OPTS{inplace} ? $OPTS{source} : "");

my $FHIN = *STDIN;
my @DATA;
my $flag;

print STDERR "processing ",($source ? $source : "*STDIN")," ...\n";
if($source) {
	$FHIN = undef;
	open $FHIN,"<",$source or die("$!\n");
}

while(<$FHIN>) {
	if(m/^\s*$/) {
		next;
	}
	if(m/<div id="(left_column)">|<div id="(header)">|<div id="(title_bar)">/) {
			$flag = $1 || $2 || $3;	
			print STDERR "Striped [$flag]\n";
	}
	elsif(m/<div id="centre_column">|<div id="body">|<div id="breadcrumbs">/) {
			$flag = "";
			push @DATA,$_;
	}
	elsif($flag) {
			next;
	}
	else {
			push @DATA,$_;
	}
}

close $FHIN if($source);


my $FHOUT = *STDOUT;

print STDERR "writing result to ",($output ? $output : "*STDOUT"), "\n";
if($output) {
	$FHOUT = undef;
	open $FHOUT,">",$output or die("$!\n");
}
print $FHOUT @DATA;
close $FHOUT if($output);






__END__

=pod

=head1  NAME

strip-perldoc-html - PERL script

=head1  SYNOPSIS

strip-perldoc-html [options] ...

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

    2013-11-22 00:46  xiaoranzzz  <xiaoranzzz@Mainstream>
        
        * file created.

=head1  AUTHOR

xiaoranzzz <xiaoranzzz@Mainstream>

=cut

#       vim:filetype=perl
