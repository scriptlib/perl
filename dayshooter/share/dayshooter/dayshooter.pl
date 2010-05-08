#!/usr/bin/perl 
###APPNAME:     dayshooter
###APPAUTHOR:   xiaoranzzz
###APPVER:		1.0
###APPDATE:		2009-06-20 20:17:43
###Version:		1.0 2009-06-20 20:17:43 by xiaoranzzz
###Version:		0.2 2008-12-31 05:33:17 by xiaoranzzz
###APPDESC:     text reader suitable for killing you day
###APPUSAGE:	[Filename]
###APPOPTION:	
use strict;
use warnings;
our $VERSION = '1.0';

my $appdir;
my $libdir;

BEGIN {
	use File::Spec;
	my $binary = File::Spec->rel2abs($0);
	my ($vol, $dirs, undef) = File::Spec->splitpath($binary);
	$appdir = File::Spec->catdir($vol,$dirs);
	$libdir = File::Spec->catdir($vol,$dirs,File::Spec->updir,File::Spec->updir,"lib");
	print STDERR $libdir,"\n";
	unshift @INC, $libdir if -d $libdir;
		require DayShooter;import DayShooter;#  qw/NDEBUG/;
}

my $app = new DayShooter(appdir=>$appdir,libdir=>$libdir);
$app->start(uri=>'http://www.google.com');
until($app->end()) {
    $app->activate();
}
