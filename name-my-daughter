#!/usr/bin/perl -w
# $Id$
package MyPlace::Script::name_my_daughter;

use strict;
use v5.8.0;
use utf8;
use MyPlace::Usage;
our $VERSION = 'v0.1';

my %OPTS;
my @OPTIONS = qw/help|h|? version|ver edit-me manual|man/;
if(@ARGV)
{
    require Getopt::Long;
    Getopt::Long::GetOptions(\%OPTS,@OPTIONS);
    MyPlace::Usage::Process(\%OPTS,$VERSION);
}

#my $p = '林';
my $p = '';
my @keywords = qw/ 语 予 伊 涵 橙 风 格 之 庭 心 扬 阳 彤 宁 冉 南 天 尔 尘 执 易 灵 知 离 秦 章 绰 自 至 良 诺 读 采 晨 /;
my @optwords = qw/ 千 纤 未 东 飞 尺 词 幼 双 声 芊 芷 若 可 宸 桐 梓 祈 思 舟 一 羽 辰 其 雨 /;
use List::Util qw/shuffle/;
binmode STDOUT,'utf8';
my %names;
foreach my $word1 (shuffle @keywords) {
	foreach my $word2 (shuffle (@keywords,@optwords)) {
	$names{$word1 . $word2} = 1;
	$names{$word2 . $word1} = 1;
	}
}
my @names = keys %names;
my $count = scalar(@names);
my $idx = 0; my $col = 8;
while($idx < $count) {
	for($idx .. $idx + $col - 1) {
		if($names[$_]) { $names[$_] = $p . $names[$_]; }
		else { $names[$_] = ""; }
	}
	printf('%6s'x($col) . "\n",@names[($idx)..($idx+$col-1)]);
	$idx +=$col;
}


__END__

=pod

=head1  NAME

name-my-daughter - PERL script

=head1  SYNOPSIS

name-my-daughter [options] ...

=head1  OPTIONS

=over 12

=item B<--version>

Print version infomation.

=item B<-h>,B<--help>

Print a brief help message and exits.

=item B<--manual>,B<--man>

View application manual

=item B<--edit-me>

Invoke 'editor' against the source

=back

=head1  DESCRIPTION

___DESC___

=head1  CHANGELOG

    2011-12-24 13:47  xiaoranzzz  <xiaoranzzz@myplace.hell>
        
        * file created.

=head1  AUTHOR

xiaoranzzz <xiaoranzzz@myplace.hell>

=cut

#       vim:filetype=perl
