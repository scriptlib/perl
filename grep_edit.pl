#!/usr/bin/env perl 
# $Id$
#===============================================================================
#         NAME: grep_edit
#  DESCRIPTION: grep which edit files in place
#       AUTHOR: xiaoranzzz <xiaoranzzz@MYPLACE>
# ORGANIZATION: MyPlace HEL ORG.
#      VERSION: 1.0
#      CREATED: 2019-02-08 02:09
#     REVISION: ---
#===============================================================================
package MyPlace::Script::grep_edit;
use strict;

our $VERSION = 'v0.1';
my @OPTIONS = qw/
	help|h|? 
	manual|man
	output|o=s
	append|a
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


my $pattern = shift;
my @words = split(/\s+/,lc($pattern));
my @files = @ARGV;
@files = qw/STDIN/ unless(@files);
print STDERR "Pattern: $pattern\n";
print STDERR "Words: " . join(", ",@words),"\n";
foreach my $filename (@files) {
	print STDERR "File: $filename\n";
	my $FI;
	if($filename eq 'STDIN') {
		open $FI,'<',*STDIN;
	}
	elsif(open $FI,'<',$filename) {
		if(!$OPTS{output}) {
			my $bk = "$filename.bak";
			if(! -f $bk) {
				print STDERR "Backup: ";
				system("cp","-av","--",$filename,$bk);
			}
		}
	}
	else {
		print STDERR "Error: opening file $filename ($!)\n";
		next;

	}
	if(!$FI) {
		print STDERR "Error: opening file $filename ($!)\n";
		next;
	}
	my @lines;
	my $total = 0;
	my $count = 0;
	print STDERR "Get: 0 out of 0 line";
	foreach(<$FI>) {
		$total++;
		my $line = lc($_);
		my $save = 1;
		foreach my $w(@words) {
			if(index($line,$w)<0) {
				$save = undef;
				#print STDERR "[NO] $_\n";
				last;
			}
		}
		next unless($save);
		$count++;
		print STDERR "\r\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\bGet: $count out of $total lines";
		push @lines,$_;
	}
	close $FI;
	print STDERR "\n";
	my $output = $OPTS{output} ? $OPTS{output} : $filename eq 'STDIN' ? undef : $filename;
	$OPTS{output} = undef;
	if($output eq 'STDIN') {
		print $_ foreach(@lines);
	}
	elsif(open my $FO,($OPTS{append} ? '>>' : '>'),$output) {
		print $FO $_ foreach(@lines);
		close $FO;
		print STDERR "Saved: $output\n";
	}
	else {
		print STDERR "Error: writting file $output ($!)\n";
	}
}



__END__

=pod

=head1  NAME

grep_edit - PERL script

=head1  SYNOPSIS

grep_edit [options] <patterns> <files>

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

    2019-02-08 02:09  xiaoranzzz  <xiaoranzzz@MYPLACE>
        
        * file created.

=head1  AUTHOR

xiaoranzzz <xiaoranzzz@MYPLACE>

=cut

#       vim:filetype=perl
