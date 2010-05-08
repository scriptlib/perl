#!/usr/bin/perl -w
package HTML;

sub get_title {
    foreach(@_) {
        my @match= $_ =~ /\<title\>\s*([^\<\>]*)\s*\<\/\s*title\>/i;
        return $match[0] if(@match);
    }
    return undef;
}

sub get_prop {
    my $tag=shift;
    my $prop=shift;
    return undef unless($tag);
    return undef unless($prop);
    my $data=join("",@_);
        my @match;
        @match= $data =~ /\<$tag\s+[^\<\>]*$prop\s*=\s*\'([^\'\<\>]+)\'\s*[^\<\>]*\>/i;
        return $match[0] if(@match);
        @match= $data =~ /\<$tag\s+[^\<\>]*$prop\s*=\s*\"([^\"\<\>]+)\"\s*[^\<\>]*\>/i;
        return $match[0] if(@match);
        @match= $data =~ /\<$tag\s+[^\<\>]*$prop\s*=([^\s\'\"\<\>]+)\s*[^\<\>]*\>/i;
        return $match[0] if(@match);
    return undef;
}

sub get_props {
    my $tag=shift;
    my $prop=shift;
    return undef unless($tag);
    return undef unless($prop);
    my @result;
    foreach(@_) {
        my @match;
        @match= $_ =~ /\<$tag\s+[^\<\>]*$prop\s*=\s*\'([^\'\<\>]+)\'\s*[^\<\>]*\>/gi;
        push(@result,@match) if(@match);
        @match= $_ =~ /\<$tag\s+[^\<\>]*$prop\s*=\s*\"([^\"\<\>]+)\"\s*[^\<\>]*\>/gi;
        push(@result,@match) if(@match);
        @match= $_ =~ /\<$tag\s+[^\<\>]*$prop\s*=([^\s\'\"\<\>]+)\s*[^\<\>]*\>/gi;
        push(@result,@match) if(@match);
    }
    return @result;
}

sub get_href {
    return get_prop("a","href",@_);
}
sub get_hrefs {
    return get_props("a","href",@_);
}

