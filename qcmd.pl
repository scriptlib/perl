#!/usr/bin/env perl 
#===============================================================================
#
#         FILE: qcmd.pl
#
#        USAGE: ./qcmd.pl  
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
#      CREATED: 2016/03/30  2:47:17
#     REVISION: ---
#===============================================================================

use strict;
use warnings;
use utf8;

use MyPlace::QuickCmd;

if(@ARGV) {
	qcmd_set(@ARGV);
	qcmd_name(join(" ",@ARGV));
}
exit qcmd_run();



