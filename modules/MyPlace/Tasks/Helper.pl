#!/usr/bin/env perl 
#===============================================================================
#
#         FILE: listener.pl
#
#        USAGE: ./listener.pl  
#
#  DESCRIPTION: 
#
#      OPTIONS: ---
# REQUIREMENTS: ---
#         BUGS: ---
#        NOTES: ---
#       AUTHOR: Eotect Nahn (eotect), eotect@myplace.hel
# ORGANIZATION: MyPlace HEL. ORG.
#      VERSION: 1.0
#      CREATED: 2016/08/27  1:02:14
#     REVISION: ---
#===============================================================================

use strict;
use warnings;
use utf8;
use MyPlace::File::Utils qw/file_write/;

my $id = shift;
my $worker = shift;
my $FEED = shift;
my $LN_FREE_FILE = shift;
my $wait = shift(@ARGV) || 1;
die "Usage: $0 ID Worker File_Input File_Free Seconds_Wait\n" unless($LN_FREE_FILE);
my $PROMPT = "Listener $id>";
my $idle = undef;
while($wait) {
	next unless(-f $FEED);
	open FI,'<',$FEED or next;
	unlink $LN_FREE_FILE;
	$idle = undef;
	my @lists;
	while(<FI>) {
		chomp;
		next if(m/^\s*#/);
		push @lists,$_;
	}
	close FI;
	unlink $FEED;
	my $count = scalar(@lists);
	my $idx = 1;
	foreach(@lists) {
		#print STDERR "[$idx/$count] $_\n";
		if($_ eq 'END') {
			print STDERR "$PROMPT END signal recieved, Aborting ...\n";
			exit 0;
		}
		print STDERR "$PROMPT $worker $_\n";
		system($worker,$_);
		$idx++;
	}
	file_write($LN_FREE_FILE);
} continue {
	print STDERR "$PROMPT IDLE ...\n" if(!$idle);
	sleep $wait;
	$idle = 1;
}

print STDERR "\n";


