#!/usr/bin/perl -w
package MyPlace::HTML;
use strict;
use Encode qw/decode/;

BEGIN {
    use Exporter;
    our @ISA=qw(Exporter);
    our @EXPORT=qw(&get_title &get_prop &get_props &get_href &get_hrefs &read_html &get_text);
}
binmode STDOUT,'utf8';
sub read_html {
    my $fh = shift;
    my @data;my $charset;
    while(<$fh>) {
        chomp;
        next if(/^\s*$/);
        push @data,$_;
        if(!$charset && /charset\s*=[\s'"]*([^\/\\\s<>"']+)/) {
            $charset=$1;
            $charset="utf8" if($charset =~ /utf/);
            $charset="gbk" if($charset =~ /^\s*gb/);
        }
    }
#    print STDERR "HTML Charset = $charset\n" if($charset);
    @data = map {$_=decode($charset,$_);} @data if($charset);
    return @data;
}

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
        @match= $data =~ /<$tag\s+[^\<\>]*$prop\s*=\s*\"([^\"\<\>]+)\"/i;
        return $match[0] if(@match);
        @match= $data =~ /\<$tag\s+[^\<\>]*$prop\s*=([^\s\'\"\<\>]+)\s*[^\<\>]*\>/i;
        return $match[0] if(@match);
    return undef;
}
sub get_text {
	my $tag=shift;
	return undef unless($tag);
	my $data = join("",@_);
	my @result;
	if($data =~ m/\<\s*$tag\s*[^\<\>]*\>(.+)\<\s*\/$tag\s*\>/gi) {
		my $text = $1;
		print STDERR "\ntext:$text\n";
		$text =~ s/\<[^\<\>]+\>//g;
		$text =~ s/&[^;]+;//g;
		push @result,$text if($text);
	}
	return join("",@result);
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
return 1;
