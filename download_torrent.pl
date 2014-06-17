#!/usr/bin/perl -w
# $Id$
package MyPlace::Script::download_torrent;
use strict;

our $VERSION = 'v0.1';
my @OPTIONS = qw/
	help|h|? 
	manual|man
	verbose|v
/;
my %OPTS;
if(@ARGV)
{
    require Getopt::Long;
    Getopt::Long::GetOptions(\%OPTS,@OPTIONS);
}
if($OPTS{'help'} or $OPTS{'manual'}) {
	require Pod::Usage;
	my $v = $OPTS{'help'} ? 1 : 2;
	Pod::Usage::pod2usage(-exitval=>$v,-verbose=>$v);
    exit $v;
}

use File::Spec;

my $VERBOSE = $OPTS{'verbose'};
my $SCRIPTDIR = $0;
$SCRIPTDIR =~ s/[\/\\]+[^\/\\]+$//;

my @SITES = (
	qw{
		http://www.520bt.com/Torrent/:HASH:
		http://torcache.net/torrent/:HASH:.torrent	
		http://torrentproject.se/torrent/:HASH:.torrent
		http://torrage.com/torrent/:HASH:.torrent
		http://zoink.it/torrent/:HASH:.torrent
		http://torrage.ws/torrent/:HASH:.torrent
	}
);
sub checktype {
	my $output = shift;
	return unless(-f $output);
	my $type = `file -b --mime-type -- "$output"`;
	if($type =~ m/torrent/) {
		return 1;
	}
	return undef;
}
sub download {
	my $output = shift;
	my $URL = shift;
	my $REF = shift(@_) || $URL;
	my @cmd = (
			qw{curl -L --compressed --fail --create-dir -A Mozilla/5.0 -m 180 --connect-timeout 15},
			'-#',
			"--referer",$REF,
			'--url',$URL,
			'-o',$output
	);
	if($VERBOSE) {
		print STDERR "\n",join(" ",@cmd),"\n";
	}
	else {
		print STDERR $URL,"\n";
	}
	if(system(@cmd) == 0) {
		if(checktype($output)) {
			return 1;
		}
		else {
			unlink($output);
		}
	}
	return undef;
}

sub process {
	my $hash = shift;
	my $title = shift;
	my $dest = shift;
	my $filename = shift;
	if($hash =~ m/^([\dA-Z]+)\s*\t\s*(.+?)\s*$/) {
		$hash = $1;
		$title = $2 if(!$title);
	}
	
	my $output = "";
	
	if(!$filename) {
		if(!$title) {
			my $getor = File::Spec->catfile($SCRIPTDIR,"gettorrent_title.pl");
			$getor =  File::Spec->catfile($SCRIPTDIR,"gettorrent_title") unless(-f $getor);
			$title = `perl "$getor" "$hash"`;
			chomp($title) if($title);
		}
		$filename = $hash . ( $title ? "_$title" : "") . ".torrent";
	}
	if($dest) {
		$output = File::Spec->catfile($dest,$filename);
	}
	else {
		$output = $filename;
	}
	
	print STDERR "==> $output\n";
	if(checktype($output)) {
		print STDERR "  File already downloaded, Ignored\n";
		return;
	}
	foreach(@SITES) {
		my $sitename = $_;
		if(m/:\/\/([^\/]+)/) {
			$sitename = $1;
		}
		my $url = $_;
		$url =~ s/:HASH:/$hash/g;
		print STDERR "Try [$sitename] ";
		if(download($output,$url)) {
			print STDERR "  [OK]\n";
			last;
		}
		else {
			print STDERR "\n";
		}
	}
}

if(@ARGV) {
	process(@ARGV);
}
else {
	my @LINES;
	my $count;
	my $index;
	while(<>) {
		chomp;
		push @LINES,$_ if($_);
	}
	$count = @LINES;
	foreach my $line(@LINES) {
		$index++;
		print STDERR "TASK $index/$count: \n";
		my @args = split(/\s*\t\s*/,$line);
		process(@args);
	}
}


__END__

=pod

=head1  NAME

download_torrent - PERL script

=head1  SYNOPSIS

download_torrent [options] ...

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

    2014-06-18 00:07  xiaoranzzz  <xiaoranzzz@MyPlace>
        
        * file created.

=head1  AUTHOR

xiaoranzzz <xiaoranzzz@MyPlace>

=cut

#       vim:filetype=perl