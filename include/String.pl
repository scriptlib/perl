#!/usr/bin/perl -w
package String;

sub strnum($$) {
    my $num=shift;
    my $len=shift;
    my $o_len = length($num);
    if(!$len or $len<=0 or $len<=$o_len) {
        return $num;
    }
    else {
        return "0" x ($len-$o_len) . $num;
    }
}
