#!/usr/bin/perl -w
# $Id$
package MyPlace::Script::convert_torrent;
use strict;

our $VERSION = 'v0.1';
my @OPTIONS = qw/
	help|h|? 
	manual|man
/;
my %OPTS;
if(@ARGV)
{
    require Getopt::Long;
    Getopt::Long::GetOptions(\%OPTS,@OPTIONS);
}
else {
	$OPTS{'help'} = 1;
}
if($OPTS{'help'} or $OPTS{'manual'}) {
	require Pod::Usage;
	my $v = $OPTS{'help'} ? 1 : 2;
	Pod::Usage::pod2usage(-exitval=>$v,-verbose=>$v);
    exit $v;
}

use Bencode qw/bencode bdecode/;
use Data::Dumper;
use MyPlace::Debug qw/to_string/;
use utf8;


sub big_word {
	my $_ = shift;
	#tr/abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ/nopqrstuvwxyzabcdefghijklmNOPQRSTUVWXYZABCDEFGHIJKLM/;
	tr/abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ/ａｂｃｄｅｆｇｈｉｊｋｌｍｎｏｐｑｒｓｔｕｖｗｘｙｚＡＢＣＤＥＦＧＨＩＪＫＬＭＮＯＰＱＲＳＴＵＶＷＸＹＺ/;
	return $_;
}

sub atoi {
	my $_ = shift;
	tr/oOlLbBzZgG/0011662299/;
	return $_;
}

sub escape {
	my $_ = shift;
	s/([~[:ascii:]])/sprintf("%X",ord($1))/ge;
	return $_;
}

my %DICT = qw/
	成人		成Ren
	榊なち		榊ナチ
	品色堂		品Se堂
	六月天		6月天
	板垣あずさ	板垣アズサ
	宮間葵		宮間あおい
	女教师		女老师
	一夜情		一Ye情
	上门服务	上Meng服务
	熟女		熟Nv
	辻さき		辻サキ
	夫妻交换	夫Qi交换
	换妻	换Qi
	苏小美		苏小Mei
	波波妹		波波Mei
	丁字裤		Ding字裤
	beautyleg	BE
	潮吹		潮Chui
	淫汁		Yin汁
	黑木麻衣	黑MU麻衣
/;

my %HZPY = qw/
	欲	Yv
	性	Xing
	做	Zuo
	交$	Jiao
	肛	Gang
	屄$	Bi
	乳	Rv
	榴$	Liu
	色	Se
	奇 	Qi
	狼	Lang
	爱$	Ai
	訊	Xun
	优$	You
	訊	Xun
	淫	Yin
	乱	Luan
	网$	Wang
	察$	Cha
	城$	Chen
	里沙 りさ
	春香 はるか
	咲	さき
	美穂 みほ
	百合 ゆり
	小夏 こなつ
	優乃	ゆうの
	愛 	あい
	奈津美	なつみ
	里子 りこ
	梓ユイ	梓えい
	翔 しょう
	瞳	ひとみ
	麻妃	まき
	沙英	さえ
	心美	ここみ
	恋		こい
/;



=safekey
	禁断
	荡妇
	第一会所
	(XXX-AV)(20989)超美爆乳！極上悩殺エロボディー連続ファック 星野あかり.wmv
	SYK-187 Beauty Venus - Risa Murakami, Yuri Kousaka, Akari Hoshino, Ai Kurosawa, Yui Komiya  星野あかり, 黖沢愛, 小宮ゆい
	お義姉さん
	静候轮回@www.5exin5ex.net@接吻和同性間亂交 黒木麻衣 星野あかり!!BWB-002
	性吧
	http://www.18p2p.com
	痴女
	誘惑
	義姉凌辱調教 
	 淫亂
	 青姦
	 輪姦
	 巨乳ギャル痴漢バス
	 人妻
	 淫
	 有码
	 強X
	義姉
	仁科百華
	雨宮琴音
	黒木麻衣
	原千尋
	春咲あずみ
	ましろ杏
	鈴音りおな
	三浦芽依
	水城奈緒
		勃起
		風間ゆみ
		長澤リカ 真中かおり
		川上ゆう 雪野ひかる
		三浦亜沙妃
		村上涼子 
			かすみ果穂
	鮎川なお
	鷹宮りょう
	森ななこ
	松すみれ
	花井メイサ  加藤ツバキ  星アンジェ 諸星セイラ	
	大沢佑香
		北條麻妃
			波多野結衣
			中出
	情色
	長澤あずさ
	性
	 官能
	 Hard\s*Core
	 脅迫
	 调教
	 伊甸园
米其林
 桐原あずさ 藤崎ひなた 楓乃々花 多岐川一葉
  顔射  姦淫
  近親 相姦 美尻 
  しすぎる三姉妹暴行 近親相姦レイプ 妃乃ひかり 柳田やよい
  愛唯偵察
  精液
赌博 
MM公寓
黒沢爱
 爱城
  千野さくら 吹石絵梨子
  坂本愛海
  澄川ロア

 情色美眉娱乐
 彩季レナ
 美脚
敏感
诱惑
誘惑
18P2P
父親愛人
悪魔
誘脚
超絶
美女
巨乳
 少妇\s+论坛
 Porn 
 情色伊甸园
 性欲
 柏拉圖秘密花園
 adult
 露出  HOTAVXXX
 华人城论坛
 Sasuke Jam Vol 4 超極上淫亂美女大暴走 星野あかり Akari Hoshino
 淫語
上原亜衣
大槻ひびき
飯田せいこ
爱城
JAV xxx169 ac168
	套图
	套圖
	weipai
	微拍
	
	小美
	黑丝
	丝袜
	
	内衣
	原味
	情趣
	洗澡
	激情
自摸
自慰
	叫床
	近親相姦 
美尻
有沢実紗
凌辱 今野梨乃
 小坂めぐる
 
痴漢
花野真衣  官能
星野桃  野中あんり
教師 痴女 
早乙女ルイ  催眠快獄
真性中出  桃太郎映像
誘惑
星野光
騎乢位
zoink
18p2p
痙攣  新藥 地獄
中出 交尾
 Slut
/;
=cut
=qustionable 
		愛咲れいら
=cut
=ok
=cut
my @indoubt = qw/


/;
my @dirty = qw/
	潮吹
	丁字裤
	苏小美
	波波妹
	夫妻交换
	换妻
	上门服务
	99bt
	JPAVGOD
	色狼
	selang
	女教师
	宮間葵
	板垣あずさ
	相沢恋
	熟女
	辻さき
	成瀬心美
	高城沙英
	援交
	六月天
	品色堂
	北条麻妃
	北川瞳
	肉欲
	性交
	性爱
	做爱
	口交
	肛交
	美屄
	美乳
	草榴
	fuck
	sexinsex
	sex
	一夜情
	色中色
	成人
	都市奇爱网
	狼友
	爱唯侦察
	dioguitar
	D.C.資訊交流網
	女优
	香坂百合
	村上里沙
	sis001
	淫乱
	乱交
	乱~交
	乱x交
	大塚咲
	妃悠爱
	妃悠愛
	真田春香
	青空小夏
	橘美穂
	星優乃
	河本愛
	黒沢愛
	榊なち
	堀口奈津美
	立花里子
	梓ユイ
	西野翔
	性吧
	娱乐城	
/;


my %filter;
foreach(@dirty) {
	my $value = $_;
	if(defined $DICT{$_}) {
		$value = $DICT{$_} || "";
	}
	if($value eq $_) {
		$value = atoi($_);
	}
	if($value eq $_) {
		$value = big_word($_);
	}
	if($value eq $_) {
		foreach my $word (keys %HZPY) {
			$value =~ s/$word/$HZPY{$word}/;
			last unless($value eq $_);
		}
	}
	$filter{$_} = $value;
}


foreach(@indoubt) {
	$filter{$_} = "INDOUBT";
}

foreach(keys %DICT) {
	$filter{$_} = $DICT{$_};
}


print STDERR to_string(\%filter,"filter"),"\n";
my %ufilter = ();
use Encode qw/find_encoding/;
my $utf8 = find_encoding("utf-8");
foreach(keys %filter) {
	$ufilter{$utf8->encode($_)} = $utf8->encode($filter{$_});
}

sub clean_text {
	my $text = shift;
	my $old = $text;
	#	print STDERR $text,"\n";
	my $suf = "";
	if($text =~ m/~(.+)\.([~\.]{1,4})$/) {
		$suf = ".$2";
		$text = $1;
	}
#	$text =~ s/([~[:ascii:]])/sprintf("%X",ord($1))/ge;
	foreach(keys %ufilter) {
		$text =~ s/$_/$ufilter{$_}/gi;
	}
	$text = $text . $suf;
	if($old eq $text) {	
		print  "\t[No change]$text\n";
		return $text,undef;
	}
	else {
		print  "\n\t$old\n\t=>$text\n";
		return $text,1;
	}
}

sub clean {
	my $tor = shift;
	my $position = shift(@_) || "ROOT";
	my $type = ref $tor;
	my $dirty = undef;
	
	if($position =~ m/piece|filehash|magnet|ed2k|nodes|announce|encoding/) {
		return ($tor,$dirty);
	}
	#if($all or $key =~ m/publisher|path|publisher|created by|name|comment|files/i) {
	
	if($type eq 'ARRAY') {
		my @values;
		my $idx = 0;
		foreach(@{$tor}) {
			my $d;
			($_,$d) = clean($_,$position . "\[$idx\]");
			$idx++;
			if($d) {
				$dirty = $d;
			}			
			push @values,$_;
		}
		return (\@values,$dirty);
	}
	elsif($type eq 'HASH') {
		foreach my $key (keys %$tor) {
			my $d;
			($tor->{$key},$d) = clean($tor->{$key},$position . "->\{$key\}");
			$dirty = $d if($d);
		}
	}
	else {
		print STDERR "Processing $position";
		my $d;
		($tor,$d) = clean_text($tor,$position);
		$dirty = $d if($d);
	}
	return $tor,$dirty;
}
sub process {
	my $filename = shift;
	my $chunks = '';
	open FI,'<:raw',$filename or die("Error opening $filename: $!\n");
	my $ok = undef;
	my $chunk = undef;
	my $bufsize = 1024;
	while($ok = read FI,$chunk,$bufsize) {
		$chunks .= $chunk if($chunk);
	}
	close FI;
	if(!(defined $ok)) {
		die("Error reading $filename: $!\n");
	}
	my $torrent = bdecode($chunks);
	#print STDERR to_string($torrent,"torrent",0,"  ","piece");
	my $dirty = undef;
	my $basename = $filename;
	$basename =~ s/.*[\/\\]//;
	$basename =~ s/\.([^\.]+)$//;
	if($basename =~ m/^([A-Fa-f0-9]+)_(.+?)\s*$/) {
		$basename = $2;
	}
	if($torrent) {
		if($torrent->{info}->{name} && !($torrent->{info}->{name} eq $basename)) {
			$torrent->{info}->{name} = $basename;
			$dirty = 1;
		}
		if($torrent->{info}->{"name.utf-8"} && !($torrent->{info}->{"name.utf-8"} eq $basename)) {
			$torrent->{info}->{"name.utf-8"} = $basename;
			$dirty = 1;
		}
		if($dirty) {
			print STDERR "Set torrent->{info}->{name} = $basename\n";
		}
		my $d = undef;
		($torrent,$d) = clean($torrent,"torrent");
		$dirty = $d if($d);
		# ($torrent->{info},$d) = clean($torrent->{info},undef,"torrent->{info}");
		# $dirty = $d if($d);
	}
	if($dirty) {
		print STDERR "Wrting $filename ...\n";
		open FO,">:raw",$filename or die("Error opening $filename:$!\n");
		print FO bencode($torrent);
		close FO;
		return 1;
	}
	else {
		print STDERR "No changes made to $filename\n";
		return undef;
	}
	#print STDERR to_string($torrent,"torrent",0,"  ","piece");
	#die(Data::Dumper->Dump([$torrent->{info}->{files}],['torrent->files']),"\n");
}

foreach(@ARGV) {
	process($_);
}



__END__

=pod

=head1  NAME

convert_torrent - PERL script

=head1  SYNOPSIS

convert_torrent [options] ...

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

    2014-06-18 23:53  xiaoranzzz  <xiaoranzzz@MyPlace>
        
        * file created.

=head1  AUTHOR

xiaoranzzz <xiaoranzzz@MyPlace>

=cut

#       vim:filetype=perl
