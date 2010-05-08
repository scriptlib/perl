#!/usr/bin/perl -w

package Filename;
use Env 'PWD';

sub filename($) {
    my $fn=shift;
    $fn =~ s{\/+$}{};
    $fn =~ s{^.*\/}{}g;
    return $fn;
}

sub basename($) {
    my $fn=&filename(shift);
    $fn =~ s/\.[^\.]*$//;
    return $fn;
}

sub fullname($) {
    my $fn=shift;
    return $fn if($fn =~ m{^\/});
    $fn =~ s{^\.\/}{};
    return $PWD . "\/" . $fn;    
}

sub parent($) {
    my $fn=&fullname(shift);
    $fn =~ s{\/+$}{};
    $fn =~ s{\/[^\/]*$}{};
    return $fn;
}
