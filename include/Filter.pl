#!/usr/bin/perl -w
###APPNAME:     include/Filter
###APPAUTHOR:   geek
###APPDATE:	Sun Sep 30 09:30:40 2007
###APPVER:	0.1
###APPDESC:	
###APPUSAGE:	
###APPEXAMPLE:	
###APPOPTION:	
my $filterDir=`pldir/filter`;
sub GetFilter($$) {
    my $name=shift;
    my $level=shift;
    $level=1 unless($level);
    return "$filterDir/$level/$name" if(-f "$filterDir/$level/$name");
    return "";
}
