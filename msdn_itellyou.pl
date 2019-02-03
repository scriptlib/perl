#!/usr/bin/env perl 
# $Id$
#===============================================================================
#         NAME: msdn_itellyou
#  DESCRIPTION: 
#       AUTHOR: xiaoranzzz <xiaoranzzz@MYPLACE>
# ORGANIZATION: MyPlace HEL ORG.
#      VERSION: 1.0
#      CREATED: 2018-11-20 01:48
#     REVISION: ---
#===============================================================================
package MyPlace::Script::msdn_itellyou;
use strict;
use utf8;
use Encode qw/find_encoding/;
use JSON qw/decode_json/;
my $UTF8 = find_encoding("utf8");

our $VERSION = 'v0.1';
my @OPTIONS = qw/
	help|h|? 
	manual|man
/;
my %OPTS;
if(@ARGV)
{
    require Getopt::Long;
	#Getopt::Long::Configure('pass_through',1);
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

sub extract_html {
	my $html = join("",@_);
	$html =~ s/[\r\n]+//g;
	my @items;
	while($html =~ m/input\s+data-url="([^"]+)"\s+value="([^"]+)"[^>]*>([^<]+)</g) {
		push @items,{
			id=>$2,
			source=>$1,
			title=>$3,
		};
	}
	return @items;
}

sub parse_json {
	my $t = join("",@_);
	my %i;
	while($t =~ m/"([^"]+)"\s*:\s*([^,]+)\s*/g) {
		$i{$1} = $2;
	}
	return %i;
}


sub search {
	my $id = shift;
	my @curl = ('curl','http://msdn.itellyou.cn/Category/Search',"--progress","#",'--referer','http://msdn.itellyou.cn');
	push @curl,"-F","keyword=$id";
	open FI,'-|',@curl or return;
	my $r = $UTF8->encode(join("",<FI>));
	close FI;
	return unless($r =~ m/"status":true/);
	my $r = decode_json($r);
	my $result = $r->{result};
	return unless($result);
	my $list = $result->{list};
	return unless($list);
	return unless(@$list);
	return @$list;
}

sub list {
	my $id = shift;
	my %lang = qw/
		中文简体 041dbbd2-c198-4523-b438-590128265d82
		英语 e15db4de-c094-4c50-822a-98ad50daba4f
		多国语言 c5fe5be2-1c54-49a0-80fb-bfab286484eb
	/;
	my @curl = ('curl',"--user-agent",'Mozilla/5.0 (Windows NT 6.1; Win64; x64; rv:52.0) Gecko/20100101 Firefox/52.0','http://msdn.itellyou.cn/Category/GetList',"--progress","#",'--referer','http://msdn.itellyou.cn');
	my @all;
	foreach(keys %lang) {
		my @cmd = (@curl,"-F","id=$id","-F","lang=$lang{$_}","-F","filter=false");
		#print @cmd,"\n";
		open FI,'-|',@cmd or next;
		#my $r = join("",<FI>);
		my $r = $UTF8->encode(join("",<FI>));
		close FI;
		#die substr($r,0,100),"\n";
		next unless($r =~ m/"status":true/);
		my $r = decode_json($r);
		my $result = $r->{result};
		next unless($result);
		next unless(@$result);
		push @all,{lang=>$_,product=>$result};
	};
	return @all;
}

sub sprint {
	my $s = shift;
	print "  "x$s,@_,"\n";
}

sub print_list {
	foreach(@_) {
		print $_->{lang},"\n";
		foreach my $p(@{$_->{product}}) {
			sprint(1,"[$p->{id}]");
			sprint(1,$p->{name});
			sprint(2,$p->{url});
			print "\n";
		}
	}
}

sub get_item {
	my $id = shift;
	my @curl = ('curl','http://msdn.itellyou.cn/Category/GetProduct',"--progress","#",'--referer','http://msdn.itellyou.cn');
	push @curl,"-F","id=$id";
	open FI,'-|',@curl or return;
	my $r = $UTF8->encode(join("",<FI>));
	close FI;
	my %i;
	#print STDERR $r,"\n";
	foreach(qw/FileName size DownLoad SHA1/) {
		if($r =~ m/"$_"\s*:\s*"([^"]+)"/) {
			$i{$_} = $1;
		}
	}
	return %i;
}
sub print_item {
	my %i = @_;
		print "[$i{id}]\n" if($i{id});
		print "$i{title}\n" if($i{title});
		print "Filename: ",$i{FileName},"\n";
		print "Size    : ",$i{size},"\n";
		print "Download: ",$i{DownLoad},"\n";
		print "SHA1    : ",$i{SHA1},"\n";

}

my $cmd = shift;
my $CMD = uc($cmd);
if($CMD eq 'GET') {
	my %i = get_item(@ARGV);
	if(%i) {
		print_item(%i);
	}
	else {
		print "Get NOTHING!\n";
	}
}
elsif($CMD eq 'SEARCH') {
	my @r = search(@ARGV);
	if(@r) {
		print_list(@r);
	}
	else {
		print "Get NOTHING!\n";
	}
}
elsif($CMD eq 'LIST') {
	my @r = list(@ARGV);
	if(@r) {
		print_list(@r);
	}
	else {
		print "Get NOTHING!\n";
	}

}
else {
	print STDERR "Command <$cmd> not supported\n";
}


__END__

=pod

=head1  NAME

msdn_itellyou - PERL script

=head1  SYNOPSIS

msdn_itellyou [options] ...

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

    2018-11-20 01:48  xiaoranzzz  <xiaoranzzz@MYPLACE>
        
        * file created.

=head1  AUTHOR

xiaoranzzz <xiaoranzzz@MYPLACE>

=cut

#       vim:filetype=perl
