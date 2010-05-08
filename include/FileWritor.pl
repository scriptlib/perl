#!/usr/bin/perl -w

package FileWritor;

sub to_file(\@$) {
    my $data=shift;
    my $fn=shift;
    return undef unless($data);
    open FO,">",$fn or return undef;
    print FO,join("",@{$data});
    close FO;
    return 1;
}
