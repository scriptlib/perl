#!/usr/bin/perl -w
###APPNAME:     download
###APPAUTHOR:   geek
###APPDATE:	Fri Sep 28 08:31:24 2007
###APPVER:	0.2
###APPDESC:	A downloader,nothing else.
###APPUSAGE:	[options] URL
###APPEXAMPLE:	download www.google.com/index.html
###APPOPTION:	-v:Verbose Output|-u:URL to download|-s:Filename for output|-d:Create directories|-n:Task name|-r:Referer URL|-b:cookie file|-l:Enable Logging
use strict;
use Cwd;
use Getopt::Std;

sub Help() {
    return system("plhelp",$0,"-h");
}

exit(Help()) unless(@ARGV);

my $OptFlag='hlvu:s:dn:r:b:';
my %OPT;

exit(Help()) unless(getopts($OptFlag,\%OPT));
exit(Help()) if($OPT{'h'});

sub message(@) {
    print STDERR @_;
}
sub output(@) {
    print STDOUT @_;
}

#my $help= $OPT{"h"} ? $OPT{"h"} : 0;
my $verbose= $OPT{"v"} ? $OPT{"v"} : 0;
my $url= $OPT{"u"} ? $OPT{"u"} : $ARGV[@ARGV-1];
my $saveas= $OPT{"s"} ? $OPT{"s"} : "";
my $createdir= $OPT{"d"} ? $OPT{"d"} : 0;
my $name= $OPT{"n"} ? $OPT{"n"} : "";
my $refer= $OPT{"r"} ? $OPT{"r"} : "";
my $cookie= $OPT{b} ? $OPT{b} : "";
my $logging= $OPT{l} ? $OPT{l} : "";

if ($url !~ m/^\w+:\/\// ) {
    message("Invaild URL:\"",$url,"\"\n");
    exit 1;
}

$url =~ s/\ /%20/g;
$refer=$url unless($refer);
if($createdir && !$saveas) {
    my $filename=$url;
    $filename =~ s/^\w+:\/+[^\/]*\///;
    $saveas=$filename;
}
if(!$saveas) {
    my $basename=$url;
    $basename =~ s/^.*\///g;
    $basename = "index.htm" unless($basename);
    $saveas=$basename;
}
if($saveas =~ m/\/$/) {
    $saveas .= "index.htm";
}

my $DOWNLOADER="curl";
my @DLOPTS=qw(-f -g -L -A Mozilla/5.0 --progress-bar --connect-timeout 60);
my $CDIR=getcwd;

my $FAILLOG="$CDIR/download.failed";
my $DOWNLOADLOG="$CDIR/download.log";

#Task Message

if($verbose) {
    message "%s\n%-8s: %s\n%-8s: %s\n%-8s: %s\n",
            $name ? "\n$name" : "",
            "URL",$url,
            "SaveAs",$saveas,
            "Refer",$refer;
}
else {
    message "\n$name$url->$saveas\n";
}

if ( -f "$saveas" ) {
    message "!!$saveas exists,downloading canceled.\n";
    exit 0;
}

for my $log($DOWNLOADLOG,$FAILLOG) {
    if (-r $log) {
        open FH,"<",$log;
        while(<FH>) {
            if( m[^$url->] ) {
                message("!!According to $log,Ingore below:\n$name\"$url\"\n");
                exit 0
            }
        }
        close(FH);
    }
}

sub DownLoad(@) {
    my $retry=4;
    my $r=0;
    while($retry) {
        $retry--;
        $r=system($DOWNLOADER,@DLOPTS,@_);
        return 2 if($r==2); #/KILL,TERM,USERINT;
        return 0 if($r==0);
        message "[Error:$r]Wait 1 second,Retry $name$url\n";
        sleep 1;
    }
    return 1;
}

my @DARG=();
if($refer) {
    push(@DARG,"--referer");
    push(@DARG,$refer);
}
if($saveas) {
    push(@DARG,"-o");
    push(@DARG,$saveas);
}
if($url) {
    push(@DARG,"--create-dirs");
    push(@DARG,$url);
}
if($cookie) {
    if(!-f $cookie) {
        print STDERR "Creating cookie for $url\n";
        my @match = $url =~ /^(http:\/\/[^\/]+)\//;
        if(@match) {
            my $domain=$match[0];
            system("curl --url '$domain' -c '$cookie' -o '/dev/null'");
        }
    }
    push(@DARG,"-b");
    push(@DARG,$cookie);
}
sub log($$) {
    return unless($logging);
    my $text=shift;
    my $fn=shift;
    open FO,">>",$fn or return;
    print FO $text;
    close FO;
}

my $r=DownLoad(@DARG);
if($r==0) {
    &log("$url->$saveas\n","$DOWNLOADLOG");
    message "\n$name$url->$saveas \[done\]\n";
    exit 0;
}
elsif($r==2) {
    message "$0 ($name$url) Killed\n";
    exit 2;
}
else {
    message "[Failed!]$name$url\n";
    unlink "$saveas" if(-f "$saveas");
    &log("$url->$saveas\n","$FAILLOG");
    output("\n");
    exit 1;
}

