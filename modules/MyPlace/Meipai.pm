#!/usr/bin/perl -w
package MyPlace::Meipai;
use strict;
use warnings;
BEGIN {
    require Exporter;
    our ($VERSION,@ISA,@EXPORT,@EXPORT_OK,%EXPORT_TAGS);
    $VERSION        = 1.00;
    @ISA            = qw(Exporter);
    @EXPORT         = qw();
    @EXPORT_OK      = qw(&extract_user_info);
}
use JSON qw/decode_json/;
use Encode qw/find_encoding/;
use MyPlace::URLRule::Utils qw/get_url/;
use utf8;
my $utf8 = find_encoding('utf8');

sub extract_user_info {
	my $text = shift;
	if($text =~ m/<h1><a[^>]+title="([^"]+)"[^>]+href="[^"]+\/u\/([^\/"\&\?]+)/) {
		return $2,$1,"meipai.com";
	}
}

sub extract_title {
	my $title = shift;
	return "" unless($title);
	$title =~ s/^\s+//;
	$title =~ s/<[^.>]+>//g;
	$title =~ s/\/\?\*'"//g;
	$title =~ s/&amp;amp;/&/g;
	$title =~ s/&amp;/&/g;
	$title =~ s/&hellip;/…/g;
	$title =~ s/[\r\n\/\?:\*\>\<\|]+/ /g;
#	$title =~ s/\x{1f60f}|\x{1f614}|\x{1f604}//g;
#	$title =~ s/[\P{Print}]+//g;
#	$title =~ s/[^\p{CJK_Unified_Ideographs}\p{ASCII}]//g;
	$title =~ s/[^{\p{Punctuation}\p{CJK_Unified_Ideographs}\p{CJK_SYMBOLS_AND_PUNCTUATION}\p{HALFWIDTH_AND_FULLWIDTH_FORMS}\p{CJK_COMPATIBILITY_FORMS}\p{VERTICAL_FORMS}\p{ASCII}\p{LATIN}\p{CJK_Unified_Ideographs_Extension_A}\p{CJK_Unified_Ideographs_Extension_B}\p{CJK_Unified_Ideographs_Extension_C}\p{CJK_Unified_Ideographs_Extension_D}]//g;
#	$title =~ s/[\p{Block: Emoticons}]//g;
	#print STDERR "\n\n$title=>\n", length($title),"\n\n";
	my $maxlen = 70;
	if(length($title) > $maxlen) {
		$title = substr($title,0,$maxlen);
	}	
	return $utf8->encode($title);
}

sub extract_info {
	my $url = shift;
	$url =~ s/m\.meipai\.com/www.meipai.com/g;
	#print STDERR "Retriving $url ...\n";
	my ($status,$html) = get_url($url,'-v');
	my %info;
	$info{host} = 'meipai.com';

#	print STDERR $html,"\n";
	if($url =~ m/meipai.com\/user\/([^\/#&?]+)/) {
		$info{uid} = $1;
		if($html =~ m/href="\/user\/(\d+)\/\?(?:catalog|category)=1"/) {
			$info{uid} = $1;
		}
		if($html =~ m/<h3 class="user-name">\s*[\t\n\r]+\s*([^\s]+)\s*<i/) {
			#class="icon icon-female"></i>
			$info{uname} = $1;
		}
		return \%info;
	}
	else {
	    my @data;
		my @pass_data;
	    my @html = split(/\n/,$html);
		my %now;
		(undef,undef,undef,$now{day},$now{month},$now{year}) = localtime(time);
		$now{year} += 1900;
	#	$info{year} = "";
		$now{month} += 1;
	#	$now{month} = "0" . $info{month} if($info{month} < 10);
	#	$now{day} = "0" . $info{day} if($info{day} < 10);
		$info{desc} = "";
		my $indesc;
		foreach(@html) {
			if(m/<span[^>]+id="shareMediaBtn"/) {
				while(m/data-([^\=]+)="([^"]+)"/g) {
					$info{shareMedia}->{$1} = $2;
				}
				last;
			}
			elsif($indesc) {
				#print STDERR "DESC:$_\n";
				if(m/<div class="detail-count no-select"/) {
					$indesc = undef;
					next;
				}
				$info{desc} .= $_;
				if(m/<\/div/) {
					$indesc = undef;
					next;
				}
			}
			elsif(m/<div class="detail-description br"/) {
				$indesc = 1;
			}
			#elsif(m/data-video="([^"]+)/) {
			#	$info{video} = $1;
			#}
			elsif(m/<img src="([^"]+mvimg\d?\.meitudata\.com\/([^"\/]+)\.jpg)/) {
				$info{image} = $1;
				$info{id} = $2;
			}
			elsif(m/<div class="detail-time pa">([^<]+)<\/div/) {
				$info{datestr} = $1;
				$info{datestr} =~ s/^\s*(.+)\s*$/$1/;
				#print STDERR "DATE:$info{datestr}\n";
				if($info{datestr} eq '前天') {
					$info{year} = $now{year};
					$info{day} = $now{day} - 2;
					$info{month} = $now{month};
				}
				elsif($info{datestr} eq '昨天') {
					$info{year} = $now{year};
					$info{day} = $now{day} -1;
					$info{month} = $now{month};
				}
				elsif($info{datestr}  =~ m/(\d+)-(\d+)-(\d+)/) {
					$info{year} = $1;
					$info{month} = $2;#($1 < 10 ? "0$1" : $1);
					$info{day} = $3;#($2 < 10 ? "0$2" : $2);
				}
				elsif($info{datestr} =~ m/(\d+)-(\d+)/) {
					$info{month} = $1;#($1 < 10 ? "0$1" : $1);
					$info{day} = $2;#($2 < 10 ? "0$2" : $2);
				}
			}
			elsif(m/ <ul id="commentContent" class="detail-comment-ul pr">/) {
				last;
			}
		}
		
		foreach(qw/year month day/) {
			$info{$_} = int($info{$_}) if($info{$_});
		}
		$info{year} += 2000 if($info{year} and $info{year} < 2000);
		if(!$info{image}) {
			return (error=>"Error parsing $url");
		}
		$info{month} ||= $now{month}; 
		$info{day} ||= $now{day};
		if($info{day} < 1) {
			$info{month} -=1;
			$info{day} = 30;
		}
		if(!$info{year}) {
			$info{year} = $now{year};
			if($info{month} > $now{month}) {
				$info{year} -= 1;
			}
			elsif($info{month} == $now{month}) {
				$info{year} -= 1 if($info{day} > $now{day});
			}
		}
		if($info{month} < 1) {
			$info{month} = 12;
			$info{year} -= 1;
		}
	
		$info{month} = "0" . $info{month} if(length($info{month}) < 2);
		$info{day} = "0" . $info{day} if(length($info{day}) < 2);
		$info{videoext} = "mp4";
		$info{imageext} = "jpg";
		if($info{desc}) {
			$info{desc} =~ s/<[^>]+>//g;
			$info{desc} =~ s/\s+$//;
			$info{desc} =~ s/^\s+//;
			$info{desc} = extract_title($utf8->decode($info{desc}));
		}
	
		$info{uid} ||= $info{shareMedia}->{'user-id'};
		$info{uname} ||= $info{shareMedia}->{'name'};
		$info{video} ||= $info{shareMedia}->{'video'};
		my $basename = $info{year} . $info{month} . $info{day} . "_" . $info{id};
		$basename .= "_" . $info{desc} if($info{desc});
		push @data,$info{video}  . "\t" . $basename ."." . $info{videoext}; 
		push @data,$info{image} . "\t" . $basename . "." . $info{imageext}; 
		$info{data} = \@data;
		$info{basename} = $basename;
	}
	return \%info;
}

sub MAIN {
	my $self = shift;
	my $OPTS = shift;
	use Data::Dumper;
	print Data::Dumper->Dump([extract_info(@_)],["*info"]),"\n";
}


#########################################################
use base 'MyPlace::Program';
use Data::Dumper;

sub OPTIONS {
	qw/
	help|h
	/;
}

return 1 if caller;
my $PROGRAM = MyPlace::Meipai->new();
exit $PROGRAM->execute(@ARGV);
1;
