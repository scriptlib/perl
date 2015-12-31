sub rotate13 {
    my @r;
    foreach(@_) {
        tr/a-zA-Z/n-za-mN-ZA-M/;
        push @r,$_;
    }
    return @r;
}
1;
