#!/usr/bin/perl -W

chomp(@lines=<STDIN>);

foreach $line(reverse(@lines)) {
    print($line,"\n");
}


