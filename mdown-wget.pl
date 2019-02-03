#!/usr/bin/env perl 
# $Id$
#===============================================================================
#         NAME: mdown-wget
#  DESCRIPTION: mdown with wget as worker
#       AUTHOR: xiaoranzzz <xiaoranzzz@MYPLACE>
# ORGANIZATION: MyPlace HEL ORG.
#      VERSION: 1.0
#      CREATED: 2019-01-26 22:32
#     REVISION: ---
#===============================================================================
package MyPlace::Script::mdown_wget;
use strict;
use MyPlace::Program::Downloader;
sub dl {
	my @WGET = qw{
		wget
		--connect-timeout 15
		--progress bar
		--continue
		--verbose
	};
	push @WGET,"--user-agent", 'Mozilla/5.0 (Android 9.0; Mobile; rv:63.0) Gecko/63.0 Firefox/63.0';
	my @cmds;
	my $arg = shift(@_);
	if($arg =~ m/^([^\t]+)(?:\t+|  +)(.*)$/) {
		push @cmds,$1,"-O",$2;
	}
	else {
		push @cmds,$arg;
	}
	push @cmds,@_;
	print STDERR join(" ","wget",@cmds),"\n";
	my $r = system(@WGET,@cmds);
	$r = $r>>8 if(($r != 0) and $r != 2);
	return $r;
};

my $mdown = new MyPlace::Program::Downloader;
$mdown->{options}->{worker} = \&dl;
my ($done,$error,$msg) = $mdown->execute(@ARGV);
if($error) {
	print STDERR "Error($error): $msg\n";
}
if($done) {
	exit 0;
}
elsif($error) {
	exit $error;
}
else {
	exit 0;
}

1;

__END__

