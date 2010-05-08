#!/usr/bin/perl -W

sub above_average {
    my @result;
    my $banlance=&average(@_);
    foreach(@_) {
        if ($_ >= $banlance) {
            push(@result, $_);
        }
    }
    return(@result);
}

sub average {
    local $sum;
    foreach(@_) {
        $sum += $_;
    }
    return($sum/@_);
}

print(&above_average(<STDIN>));
