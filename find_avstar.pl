#!/usr/bin/perl -w
use strict;
my $pdir = $0;
$pdir =~ s/[^\/\\]+$//;
$pdir =~ s/[\/\\]+$//;
$pdir = "." unless($pdir);
my $prog = "$pdir/find_name.pl";

my $suggest_directory = shift;
if($suggest_directory and ($suggest_directory ne '--suggest')) {
	unshift @ARGV,$suggest_directory;
	$suggest_directory = undef;
}

if(!@ARGV) {
	my $pname = $0;
	$pname =~ s/.*[\/\\]+//;
	print STDERR "find_avstar v1.0\n";
	print STDERR "  This program will try to figure out\n";
	print STDERR "directory for specified names in hand\n";
	print STDERR "coded directories.\n";
	print STDERR "Usage:\n";
	print STDERR "    $pname [--suggest] [name1,name2] [name3,name4]\n";
	exit 1;
}
my @args = (
	"--append",
	"/myplace/.x/search/todo/jav",
	"--cwd",
);
push @args,"--suggest" if($suggest_directory);
exec($prog,@args,@ARGV);

