#!/usr/bin/perl 
# $Id$
#===============================================================================
#         NAME: icmd-downloader
#  DESCRIPTION: 
#       AUTHOR: xiaoranzzz <xiaoranzzz@MyPlace>
# ORGANIZATION: MyPlace HEL ORG.
#      VERSION: 1.0
#      CREATED: 2022-07-19 00:06
#     REVISION: ---
#===============================================================================
package MyPlace::Script::icmd_downloader;

use strict;
use warnings;
use utf8;
use MyPlace::ICmd;
if(!@ARGV) {
	exit icmd_start($0);
}

my $state = icmd_parse(@ARGV);

if($state->{start}) {
	exit icmd_start($0,@ARGV);
}


sub find_script {
	my $script = shift;
	foreach my $prefix ("./","./icmd-","./icmd/","./.icmd/") {
		foreach my $suffix("",".sh",".pl",".py") {
			my $file = $prefix . "$script" . $suffix;
			if((-f $file) and (-x $file)) {
				return $file;
			}
		}
	}
	return "icmd-downloader-$script";
}

my $inline = $state->{inline};
my $cmd = $state->{cmd};
my $data = $state->{data};
my @words = $state->{args} ? @{$state->{args}} : ();
my $verb = uc($cmd);

if(!$verb) {
	print "#ICMD:ECHO Nothing to do\n";
	exit 0;
}

my %SHORTCUTS = (
	'h'=>'help',
	'a'=>'add',
	'v'=>'view',
	'd'=>'download',
	'l'=>'list',
);

foreach(keys %SHORTCUTS) {
	if($verb eq uc($_)) {
		$verb = uc($SHORTCUTS{$_});
	}
}

if($verb =~ m/^(?:HELP)/) {
	print STDERR "

$0	-	interactive downloader use MyPlace::ICmd

	help	 => display this text

	view	 => view urls

	add		 => add urls

	download => start download

	list	 => list directory
";
	$verb = 'ECHO';
}

elsif($verb eq 'ADD') {
	$verb = 'LOCALSCRIPT';
	$cmd = find_script('add');
}
elsif($verb eq 'VIEW') {
	$verb = 'LOCALSCRIPT';
	$cmd = find_script('view');
}
elsif($verb eq 'DOWNLOAD') {
	$verb = 'LOCALSCRIPT';
	$cmd = find_script('download');
}
elsif($verb =~ m/^HTTPS?:/) {
	unshift @words,$cmd;
	$verb = 'LOCALSCRIPT';
	$cmd = find_script('add');
}

if($verb eq 'START') {
	exit icmd_prompt('[URL?]');
}
elsif($verb eq 'LOCALSCRIPT') {
	$state->{pos} = 'end';
	$state->{"system.echo"} = undef;
	exit icmd_execute($state,$cmd,@words);

}
elsif($verb eq 'LIST' or $verb eq 'LS') {
	$state->{pos} = 'end';
	if($data and !$inline) {
		icmd_execute($state,'ls','-ld','--',@words);
		$state->{data} = "$data/";
		icmd_execute($state,'ls','-l','--',@words);
	}
	else {
		icmd_execute($state,'ls',@words);
	}
}
elsif($verb eq 'MINTTY') {
	$state->{pos} = 'end';
	exit icmd_execute($state,'mintty',@words);
}
elsif($verb eq 'CYGWIN') {
	$state->{pos} = '-1';
	exit icmd_execute($state,'cygstart','cygwin.bat','--no-login',@words);
}
elsif($verb eq 'ECHO') {
	exit icmd_execute($state,'echo',@words);
}
elsif($verb eq 'TOOLATE') {
	$state->{pos} = 'end';
	exit icmd_execute($state,$cmd,@words);
}
else {
	exit icmd_unknown($verb,@words);
}
