#!/usr/bin/env perl 
# $Id$
#===============================================================================
#         NAME: move_torrents
#  DESCRIPTION: 
#       AUTHOR: xiaoranzzz <xiaoranzzz@MyPlace>
# ORGANIZATION: MyPlace HEL ORG.
#      VERSION: 1.0
#      CREATED: 2016-11-05 01:01
#     REVISION: ---
#===============================================================================
package MyPlace::Script::move_torrents;
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
use File::Spec::Functions qw/catdir/;
my $DST = shift;
my $filelist = shift;
if(-f $DST) {
	unshift @ARGV,$filelist if($filelist);
	$filelist = $DST;
	$DST = shift;
}
$DST =~ s/"+$//;
die("Directory not exists:$DST\n") unless(-d $DST);
my @files = @ARGV;
if(@files) {
	unshift @files,$filelist;
}
elsif(open FI,'<',$filelist) {
	foreach(<FI>) {
		chomp;
		push @files,$_;
	}
	close FI;
}
else {
	unshift @files,$filelist;
}
my $count = scalar(@files);
die("Nothing to do!\n") unless($count>0);
foreach(@files) {
	if(!-f $_) {
		print STDERR "File not exists:$_\n";
		next;
	}
	my $name = $_;
	$name =~ s/(?:\.MASKED\.|\.)(?:txt|torrent)$//i;
	$name =~ s/_[a-fA-F0-9]{40}$//;
	$name =~ s/_[\d\.]+(?:mb|m|g|gb)$//i;
	$name =~ s/^\s*[A-Za-z0-9\s\.\-\_]+\@\s*//;
	$name =~ s/^\s*[A-Za-z0-9\s\.\-\_]+\@\s*//;
	$name =~ s/　+/ /g;
	$name =~ s/\s{2,}/ /g;
	$name =~ s/^\s+//;
	$name =~ s/\s+$//;
	$name =~ s/^\[*([A-Za-z]{3,})[_-]?(\d{3,})[\_\-\s\]]*/\U$1-$2_/;
	my $dstd = catdir($DST,$name);
	print STDERR "$_\n=>$DST\n\t$name\n";
	mkdir $dstd unless(-d $dstd);
	system('move',$_,$dstd);
}

__END__

=pod

=head1  NAME

move_torrents - PERL script

=head1  SYNOPSIS

move_torrents [options] INPUT_LIST_FILE TARGET_PATH ...

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

    2016-11-05 01:01  xiaoranzzz  <xiaoranzzz@MyPlace>
        
        * file created.

=head1  AUTHOR

xiaoranzzz <xiaoranzzz@MyPlace>

=cut

#       vim:filetype=perl
