#!/usr/bin/perl -w

package BookParser;

sub get_parser_dir() {
    return "/share/perl/bookparser";
}

sub get_domain($) {
    my $domain = shift;
    $domain =~ s/^[^\/]*\/\///;
    $domain =~ s/\/+.*$//;
    return $domain;
}

sub get_parser($) {
    my $parserd=get_parser_dir();
    my $domain = &get_domain(shift);
    my @pref=("","www.","$parserd\/","$parserd\/www.");
    my @suf=("",".pl");
    my $parser="";
    foreach my $p(@pref) {
        foreach my $s(@suf) {
            $parser="$p$domain$s" if(-f "$p$domain$s");
            last if($parser);
        }
        last if($parser);
    }
    $parser="./$parser" if($parser and $parser =~ m/^[^\/]/);
    return $parser;
}


