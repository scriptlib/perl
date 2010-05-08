#!/usr/bin/perl -w
###APPNAME:     htm2txt
###APPAUTHOR:   xiaoranzzz
###APPDATE:	Tue Mar 11 05:03:49 2008
###APPVER:	0.1
###APPDESC:     convert html file download from book.sina.bom.cn to txt	
###APPUSAGE:	[htmlfile] [rootId,[rootId,...] [filter,[filter,...]]]  
###APPEXAMPLE:	htm2txt booksrc/1.shtml "content,article" "sina.com" \n\tcat booksrc/1.shtml | htm2txt
###APPOPTION:	
use strict;
use HTML::TreeBuilder;
package HTML::Convertor;

sub to_text(\@\@\@) {
    my $src=shift;
    my $rootid=shift;
    my $filter=shift;
    return undef unless($src);

    my $tree = HTML::TreeBuilder->new();
    $tree->store_comments(0);
    foreach(@{$src}) {
        $tree->parse($_);
    }
    $tree->eof();
    my @nodes;
    if($rootid) {
        foreach(@{$rootid}) {
            last if(@nodes);
            @nodes = ($tree->look_down("id",$_));
        }
        foreach(@{$rootid}) {
            last if(@nodes);
            @nodes = ($tree->look_down("class",$_));
        }
    }
    push(@nodes,$tree) unless(@nodes);
    my $blanks=0;
    my $blank_exp=qr/^[\s\n]+$/;
    my @result;
    foreach my $text(getNodeText($nodes[0])) {
        next unless($text);
        if($filter) {
            foreach my $f(@{$filter}) {
                $text =~ s/$f//g;
            }
        }
        if($text =~ $blank_exp) {
            $blanks++;
        }
        else {
            $text .= ($blanks>1 ? "\n\n" : "\n") if($blanks);
            $blanks=0;
            push(@result,$text);
        }
    }
    $tree->delete();
    return @result;
}

sub insideP($);
sub insideP($) {
    my $node = shift;
    return 0 unless($node);
    my $parent = $node->parent;
    return 0 unless($parent);
    return 1 if($parent->tag eq "p");
    return insideP($parent);
}

sub getNodeText($);
my $block_exp=qr/^p|pre|br$/;
my $ingore_exp=qr/^script|style|meta|link$/;
sub getNodeText($) {
    my $node = shift;
    if(ref $node) {
        my @result;
        my $tagname = $node->tag;
#        print STDERR "processing $tagname ...\n";
        return undef if($tagname =~ $ingore_exp);
        push(@result,$tagname eq "br" ? "\n" : "\n\n") if($tagname =~ $block_exp);
        return undef if($tagname eq "a" and !insideP($node));
        push(@result,getNodeText($_)) foreach($node->content_list);
        return @result;
    }
    return unless($node);
    return ($node);
}

