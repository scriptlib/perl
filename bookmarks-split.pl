#!/usr/bin/perl -w
# $Id$
package MyPlace::Script::bookmarks_split;
use strict;

our $VERSION = 'v0.1';
my @OPTIONS = qw/
	help|h|? 
	manual|man
	lines|l=i
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

my $source = shift;
die("File not exists: $source\n") unless($source && -f $source);


my $basename;
my $ext;
if($source =~ m/(.+)\.([^\.]+)$/) {
	$basename = $1;
	$ext = $2;
}
else {
	$basename = $source;
	$ext = 'html';
}

my @head;
my @bookmarks;
my @foot;
my $lines = $OPTS{lines} || 400;

open FI,'<:utf8',$source or die("$!\n");
while(<FI>) {
	chomp;
	if(@foot) {
		if(m/<DT>/) {
			push @bookmarks,@foot,$_;
			@foot = ();
		}
		else {
			push @foot,$_;
		}
	}
	elsif(@bookmarks) {
		if(m/[<\/]DL>/) {
			push @foot,$_;
		}
		else {
			push @bookmarks,$_;
		}
	}
	elsif(@head) {
		if(m/<DT>/) {
			push @bookmarks,$_;
		}
		else {
			push @head,$_;
		}
	}
	else {
		push @head,$_;
	}
}

my $count = @bookmarks;
my $pages = int($count / $lines);
$pages++ if(($pages * $lines) < $count);
$pages = 1 if($pages < 1);

print STDERR join("\n",('HEAD:',@head)),"\n\n";
print STDERR join("\n",('FOOT:',@foot)),"\n\n";
print STDERR join("\n",('BOOKMARKS:',"$count lines, $pages pages.")),"\n";


$basename .= '.d' if(-f $basename);
if(! -d $basename) {
	mkdir $basename or die("$!\n");
}

for(my $i=1;$i<$pages+1;$i++) {
	my $start = $i*$lines - $lines;
	my $end = $start + $lines - 1;
	$end = $count -1 if($end >= $count);

	my $output = "$basename/$i.$ext";
	print STDERR "[$start .. $end] Writting $output ...";
	open FO,'>:utf8',$output or die("$!\n");
	print FO join("\n",@head),"\n";
	print FO join("\n",@bookmarks[$start .. $end]),"\n";
	print FO join("\n",@foot),"\n";
	close FO;
	print STDERR "\t[OK]\n";
}

__END__

=pod

=head1  NAME

bookmarks-split - PERL script

=head1  SYNOPSIS

bookmarks-split [options] ...

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

    2012-09-22 19:23  xiaoranzzz  <xiaoranzzz@myplace.hell>
        
        * file created.

=head1  AUTHOR

xiaoranzzz <xiaoranzzz@myplace.hell>

=cut

#       vim:filetype=perl
