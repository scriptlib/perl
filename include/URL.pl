#!/usr/bin/perl -w
###APPNAME:     URL Module
###APPAUTHOR:   xiaoranzzz
###APPDATE:	Fri Sep 21 12:11:45 2007
###APPVER:	0.1
###APPDESC:     URL Module for perl script
###APPEXAMPLE:	eval `plinclude URL` | do `plfile URL`
###Export:      GetBaseUrl($)\n\tGetRootUrl($)\n\tFullUrl($$@)
package URL;
#http://www.google.com/intl/
sub GetBaseUrl($) {
    my $result=shift; 
    if (! $result) {return "";}
    if ($result !~ /^http:\/\//i) {
        $result = "http://" . $result;
        $result =~ s/^http:\/\/\/*/http:\/\//;
    }
    $result =~ s/http:\/\/(.*)\/[^\/]*$/http:\/\/$1/;
    $result .= "/";
    $result =~ s/([^:\/])\/\//$1\//g;
    return $result;
}

sub domain($) {
    my $result=shift;
    $result =~ s/^.*:\/\///g;
    $result =~ s/\/.*$//;
    return $result;
}

#http://www.google.com
sub GetRootUrl($) {
    my $result=shift;
    if ($result !~ /^http:\/\//i) {
        $result = "http://" . $result;
        $result =~ s/^http:\/\/\/*/http:\/\//;
    }
    $result =~ s/^http:\/\/([^\/]*).*/http:\/\/$1/;
    return $result;
}

sub FullUrl($$@) {
    my $base = shift;
    my $root = shift;
    my @result=();
    foreach(@_) {
        my $url=$_;
        if ($url =~ /^\//) {
            $url = $root . $url;
        }
        else {
            if ($url !~ /^http:\/\//i) {
                $url = $base . $url;
            }
        }
        if ($url !~ /^http:\/\//i) {
            $url = "http://" . $url;
        }
        push @result,$url;
    }
    return @result;
}


