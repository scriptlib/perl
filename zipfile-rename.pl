#!/usr/bin/perl
use strict;
open FI,'<','Encoding Errors.txt' or die("$!\n");
foreach(<FI>) {
	chomp;
	s/[\r\n]+$//;
	if(m/^(.+)\s+-\>\s+(.+)$/) {
		my $new = $1;
		my $old = $2;
		if(-f $old) {
			if($new =~ m/\//) {
				my $pd = $new;
				$pd =~ s/\/[^\/]+$//;
				if(! -d $pd) {
					system("mkdir","-p","-v",$pd);
				}
			}
			print STDERR "Rename $old => $new ...\n";
			rename $old,$new;
		}
	}
}
close FI;

