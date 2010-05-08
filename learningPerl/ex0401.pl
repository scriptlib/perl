#!/usr/bin/perl -W

sub total() {
    $sum=0;
    foreach(@_) {
        $sum += $_;
    }
    return $sum;
}

print("Result:",&total(@ARGV),"\n");
