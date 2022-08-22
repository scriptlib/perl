#!/usr/bin/env perl 
#===============================================================================
#
#         FILE: add.pl
#
#        USAGE: ./add.pl  
#
#  DESCRIPTION: 
#
#      OPTIONS: ---
# REQUIREMENTS: ---
#         BUGS: ---
#        NOTES: ---
#       AUTHOR: Eotect Nahn (eote), eotect@myplace.hel
# ORGANIZATION: MyPlace HEL ORG.
#      VERSION: 1.0
#      CREATED: 2022/06/29  2:04:23
#     REVISION: ---
#===============================================================================

use strict;
use warnings;
use utf8;

my @all;
foreach(@ARGV) {
	push @all,split(/(?:\t|\n|    +)/,$_);
}
open FO,">>","urls.lst";
sub write_url {
	my $url = shift;
	my $title = shift;
	print STDERR "Add: $url";
	print FO "m3u8:$url";
	if($title) {
		print STDERR " => $title";
		print FO "\t$title.ts";
	}
	print STDERR "\n";
	print FO "\n";
}
my $last_url = undef;
my $last_title = undef;
while(@all) {
	my $arg = shift(@all);
	if($arg =~ m/^https?:/i) {
		if($last_url) {
			&write_url($last_url,$last_title);
		}
		$last_url = $arg;
		$last_title = undef;
	}
	else {
		$last_title = $last_title ? $last_title . " " . $arg : $arg;
	}
}
&write_url($last_url,$last_title) if($last_url);
close FO;

