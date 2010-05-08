#!/usr/bin/perl
#Book parser for book.sina.com.cn
#Date Created:Sat Mar 22 23:17:59 CST 2008
use strict;
use XML::Simple;
use Data::Dumper;

sub getTextBetween {
    my $text=shift;
    my $begin=shift;
    my $end=shift;
    $end='[\<\n]' unless($end);
    my @match = $text =~ m{$begin\s*([^\<\>]*)\s*$end}i;
    return $match[0] if(@match);
    return "";
}

my %book;
$book{source}=shift;

my @match = ($book{source} =~ /^(http:\/\/|)(.*\/)catalog\.php\?book=([0-9]+)/);
if(@match) {
        $book{base}=$match[1];
        $book{dirname}=$match[2];
}
else {
    if($book{source} =~ /\/$/) { 
        $book{source} .= "index.shtml";
    }
    @match=($book{source} =~ /^(http:\/\/|)([^\/]+)\/.*\/([^\/]+)\/[^\/]*$/);
    if(@match) {
    $book{base}=$match[1];
    $book{dirname}=$match[2];
    }
}

die("Invalid index source:\n$book{source}\n") unless(@match);

open(SOURCE,"-|", "iconv -f gb2312 -t utf8 -c");
my $TEXT="[^\<\>]*";
my @pages=(());
while(<SOURCE>) {
    unless($book{title}) {
        $book{title} = getTextBetween($_,'\<\s*title\s*\>');
        $book{title} =~ s/_.*$//g;
        $book{title} =~ s/.*(代表作|作品)：//g;
    }
    unless($book{author}) {
        $book{author} = getTextBetween($_,'\<span class=td_m\>作者：\<\/span\>\<a[^\>\<]*\>\<span class=td_m\>');
        $book{author} = getTextBetween($_,"\<span\>作者：") unless($book{author});
    }
    unless($book{description}) {
        $book{description} = getTextBetween($_,
                '\<meta\s*name=\"*description\"*\s*content=\"',
                '\"\s*\>');
    }
    unless($book{about}) {
        $book{about} = getTextBetween($_,'\<span class=td_m\>');
    }
    unless($book{cover}) {
        my @match = $_ =~ /src\s*=\s*(.*$book{dirname}.*\.jpg)/;
        if(@match) {
            $book{cover}=$match[0];
        }
    }
    my @match = $_ =~ /\<a[^\<\>]*href\s*=\s*($TEXT$book{dirname}${TEXT}html)$TEXT\>($TEXT)\<\/a\>/i;
    @match = $_ =~ /\<a[^\<\>]*href\s*=\s*(\/longbook\/$TEXT\.shtml)$TEXT\>($TEXT)\<\/a\>/i unless(@match);
    if(@match) {
        next if($match[0] =~ /index/);
        $match[1] =~ s/^\s*[0-9]*//g;
        $match[1] =~ s/^．\s*//;
        $match[0] =~ s/\"//g;
        push(@pages,{"title"=>$match[1],"url"=>$match[0]});
    }
}

$book{encoding}="gb2312";
$book{filter}='^.*(新浪|相关链接|读书频道).*$';
$book{contentId}='contTxt,artibody,article';
$book{pages}=\@pages;
$book{title}=$book{dirname} unless($book{title});
my $xml = XMLout(\%book,SuppressEmpty=>1,KeyAttr=>[],NoAttr=>1,NumericEscape=>0) or die("$!\n");
print $xml;


