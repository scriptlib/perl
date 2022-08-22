#!/usr/bin/env perl 
#===============================================================================
#
#         FILE: view.pl
#
#        USAGE: ./view.pl  
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
#      CREATED: 2022/06/29  2:09:17
#     REVISION: ---
#===============================================================================

use strict;
use warnings;
use utf8;

if(open FI,"<","urls.lst") {
	foreach(<FI>) {
		s/\t/ => /;
		print STDERR $_;
	}
	close FI;
}
else {
	print STDERR "Nothing to view";
}

