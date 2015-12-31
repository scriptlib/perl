#!/usr/bin/perl -w
###APPNAME:     htm2txt
###APPAUTHOR:   xiaoranzzz
###APPDATE:	Tue Mar 11 05:03:49 2008
###APPVER:	0.1
###APPDESC:     convert html to plain text	
###APPUSAGE:	[htmlfile] [rootId,[rootId,...] [filter,[filter,...]]]  
###APPEXAMPLE:	htm2txt booksrc/1.shtml "content,article" "sina.com" \n\tcat booksrc/1.shtml | htm2txt
###APPOPTION:	
package MyPlace::HTML::Convertor;
use strict;
no warnings;
use HTML::TreeBuilder;

BEGIN {
    use Exporter ();
    our ($VERSION,@ISA,@EXPORT,@EXPORT_OK,%EXPORT_TAGS);
    $VERSION        = 1.00;
    @ISA            = qw(Exporter);
    @EXPORT      = qw(&text_from_string &text_from_file &text_from_node);
}


sub text_from_file {
    my $file=shift;
    my $rootid=shift;
    my $filter=shift;
    open FI,"<",$file or return undef;
    my @src=<FI>;
    close FI;
    return text_from_string(\@src,$rootid,$filter);
}

sub text_from_string {
    my $src=shift;
    my $start=shift;
    my $end=shift;
    my $rootid=shift;
    my $filter=shift;
    return undef unless($src);
    my @text_src;
    if(ref $src) {
        my $started = $start ? 0 : 1;
        foreach(@{$src}) {
            if($started) {
                push @text_src,$_;
                if($end and $_ =~ m/$end/i) {
                    last;
                }
            }
            else {
                if($_ =~ m/$start/i) {
                    $started=1;
                    push @text_src,$_;
                }
            }
        }
    }
    else {
        push @text_src,$src;
    }
    my $tree = HTML::TreeBuilder->new();
    $tree->store_comments(0);
    foreach(@text_src) {
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
    my $result = text_from_node($nodes[0],$filter);
    $tree->delete();
    return $result;
}

sub text_from_node {
    my $node =shift;
    my $filter = shift;
    my $blanks=0;
    my $blank_exp=qr/^[\s\n]+$/;
    my @result;
    foreach my $text(getNodeText($node)) {
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
            push @result,($blanks>=1 ? "\n\n" : "\n") if($blanks);
            push(@result,$text);
            $blanks=0;
        }
    }
    return \@result;
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
my $block_exp=qr/^(:?p|pre|br|div|h\d+)$/i;
my $ingore_exp=qr/^(:?script|style|meta|link)$/i;
sub getNodeText($) {
    my $node = shift;
    if(ref $node) {
        my @result;
        my $tagname = lc($node->tag);
        #print STDERR "processing $tagname ...\n";
        if($tagname =~ $ingore_exp) {
            #print STDERR "ingore tag that matched $ingore_exp\n";
        }
        elsif($tagname eq "a" and !insideP($node)) {
            #print STDERR "ingore <A> if not inside <P>.\n";
        }
        else {
            if($tagname =~ $block_exp) {
                #print STDERR "is block element,append \\n\n";
                push(@result, ($tagname eq "br" ? "\n" : "\n\n"));

            }
            push(@result,getNodeText($_)) foreach($node->content_list);
        }
        return @result;
    }
    else {
        #print STDERR "Get text node :","'$node'","\n";
        return ($node);
    }
}

return 1;
