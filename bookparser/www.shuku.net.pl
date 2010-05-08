#!/usr/bin/perl -w
#Book parser for www.shuku.net
#Example Url:http://www.shuku.net/novels/gulong/bianlang/bianlang.html
#Date Created:Sat Mar 22 23:17:59 CST 2008
use strict;
use HTML::TreeBuilder;
use Data::Dumper;
use XML::Simple;
my $url=shift;
my %book;
my $tree=HTML::TreeBuilder->new();

open FI,"-|","gb2utf";
while(<FI>){
    $tree->parse($_);
}
$tree->eof();
close FI;

#$tree->dump();

$book{source}=$url;
$book{encoding}="gb2312";

foreach my $title_tag("title","h1") {
    my @t=$tree->find($title_tag);
    $book{title}=$t[0]->as_text() if(@t);
    last if($book{title});
}

$book{pages}=();

foreach my $A ($tree->find("a")) {
    my $href = $A->attr("href");
    next unless($href =~ /^[^\/]+\.html$/i);
    push(@{$book{pages}},{title=>$A->as_text,url=>$A->attr("href")})
}
my $xml = XMLout(\%book,SuppressEmpty=>1,KeyAttr=>[],NoAttr=>1,NumericEscape=>0) or die("$!\n");
print $xml;
