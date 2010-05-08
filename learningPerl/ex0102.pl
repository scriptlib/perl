#!/usr/bin/perl -W

@lines=`perldoc -u -f atan2`;

foreach(@lines) {
    s/\w<([^>]+)>/\U$1/g;
    print;
}
