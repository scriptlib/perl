#!/usr/bin/perl -w
use strict;
use Cwd qw/getcwd/;
my $cwd = getcwd;
my $pdir = $0;
$pdir =~ s/[^\/\\]+$//;
$pdir =~ s/[\/\\]+$//;
$pdir = "." unless($pdir);
foreach(@ARGV) {
	print STDERR "processing $_\n";
	next unless($_);
	my $n = $_;
	$n =~ s/\s*,.*//;
	my $target_dir = `"$pdir/find_avstar.pl" --suggest "$n"`;
	chomp($target_dir);
	print STDERR "FOR:    $n\n";
	print STDERR "TARGET: $target_dir\n";
	if($target_dir and chdir $target_dir) {
		system("$pdir/new_name.pl","-r","avstars",$_);
		chdir $cwd;
	}
	else {
		print STDERR "Error: Directory not accessible\n";
	}
}

