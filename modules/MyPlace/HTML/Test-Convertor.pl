#!/usr/bin/perl -w

do `IncludeFile HTML/Convertor`;
print "$@$!\n";
my @src;
while(<>) {
    push(@src,$_);
}
print join("\n",HTML::Convertor::to_text(\@src,\@ARGV));

