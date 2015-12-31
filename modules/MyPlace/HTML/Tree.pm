#!/usr/bin/perl -w
package MyPlace::HTML::Tree;
use HTML::Element;
no warnings;

BEGIN {
    use Exporter;
    our @ISA=qw(Exporter);
    our @EXPORT=qw(&get_title &get_prop &get_props &get_href &get_hrefs);
}

sub get_title($) {
    my $tree=shift;
    my @tags = get_tags($tree,"title");
    return undef unless(@tags);
    return $tags[0]->as_text();
}

sub get_tags($$) {
    my $tree=shift;
    my $tag=shift;
    bless $tree,"HTML::Element";
    return $tree->find($tag);
}

return 1;
