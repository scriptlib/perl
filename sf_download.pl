#!/usr/bin/env perl 
# $Id$
#===============================================================================
#         NAME: sf_download
#  DESCRIPTION: downloader for sourceforge.net project files
#       AUTHOR: xiaoranzzz <xiaoranzzz@MyPlace>
# ORGANIZATION: MyPlace HEL ORG.
#      VERSION: 1.0
#      CREATED: 2015-12-06 00:47
#     REVISION: 1
#===============================================================================
package MyPlace::Script::sf_download;
use MyPlace::String::Utils qw/strtime/;
use MyPlace::Message::Tee;
use strict;

our $VERSION = 'v0.1';
my @OPTIONS = qw/
	mirror|m=s
	dest|d=s
	include=s
	exclude=s
	accept=s
	reject=s
	log|l=s
	path|p=s
/;
my %OPTS;
my @OLD_ARGV = @ARGV;
if(@ARGV)
{
    require Getopt::Long;
	Getopt::Long::Configure('pass_through');
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

sub newmsg {
	return strtime(),": ",@_;
}

my %MIRRORS  = (
	master=>'master',
	jaist=>'jaist',
	excellmedia=>'excellmedia',
	netcologne=>'netcologne',
	svwh=>'svwh',
	
);
my %ua = (
	'android'=>'Mozilla/5.0 (Android 9.0; Mobile; rv:61.0) Gecko/61.0 Firefox/61.0',
	'firefox'=>'Mozilla/5.0 (Windows NT 6.1; rv,2.0.1) Gecko/20100101 Firefox/4.0.1',
	'ie'=>'Mozilla/5.0 (compatible; MSIE 9.0; Windows NT 6.1; Trident/5.0;',
	'chrome'=>'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_7_0) AppleWebKit/535.11 (KHTML, like Gecko) Chrome/17.0.963.56 Safari/535.11',
	'iphone'=>'Mozilla/5.0 (iPhone; U; CPU iPhone OS 4_3_3 like Mac OS X; en-us) AppleWebKit/533.17.9 (KHTML, like Gecko) Version/5.0.2 Mobile/8J2 Safari/6533.18.5',
);
my @WGET = (
	qw{-e robots=off --progress=dot:mega --restrict-file-names=windows --max-redirect=0},
	qw{-nc -nH -x --cut-dirs=2 -np},
	#qw{-r --regex pcre},
	qw{-o /dev/stdout},
);
push @WGET,'-U',$ua{firefox};

my %WGET_DEF = (
	#'reject-regex'=>'C=',
	#'R','index.htm,index.html',
	#'X','/icons/,/icon/',
);
foreach my $opt(keys %WGET_DEF) {
	my $short = length($opt) > 1 ?  0 : 1;
	my $pre = $short ? '-' : '--';
	if($OPTS{$opt}) {
		push @WGET,$pre . $opt, $OPTS{$opt};
	}
	else {
		push @WGET,$pre . $opt, $WGET_DEF{$opt};
	}
}

foreach(qw/include exclude reject accept/) {
	$OPTS{$_} = qr/$OPTS{$_}/i if($OPTS{$_});
}

my $LOGFILE = $OPTS{log} ? $OPTS{log} : 'sf_download.log';
my $TEE = MyPlace::Message::Tee->new(
	$LOGFILE,
	filemode=>'>>',
	stderr=>1,
);

sub p_tee {
	$TEE->put(newmsg(@_));
}
sub tee {
	$TEE->put(@_);
}
sub clean {
	my $t = shift;
	return unless($t);
	return unless(-d $t);
	p_tee("  Prepare> Cleaning up index files\n");
	if(!open FI,"-|",'find',$t,qw/-iname index.html -or -iname index.htm/) {
		p_tee("  Prepare> Error bring up <find>: $!\n");
		return undef;
	}
	tee('-'x40,"\n");
	my $count = 0;
	my @files;
	while(<FI>) {
		chomp;
		next unless($_);
		$count++;
		push @files,$_;
	}
	close FI;
	if($count) {
		system("rm","-v","--",@files);
		p_tee("  Prepare> $count files deleted\n");
	}
	else {
		p_tee("  Prepare> Nothing for cleaning\n");
	}
	tee('-'x40,"\n");
	return 1;
}

sub download {
	my @cmds =  @WGET;
	p_tee("  Command> ",join(" ","wget",@cmds,@_),"\n");
	if(!open FI,'-|','wget',@cmds,@_) {
		p_tee("Error bring up <wget>: $!\n");
		return undef;
	}
	p_tee("  Execute>\n");
	tee('-'x40,"\n");
	while(<FI>) {
		tee("  " . $_);
	}
	tee('-'x40,"\n");
	close FI;
	return 1;
}

sub download {
	my @cmds =  @WGET;
	#p_tee("  Command> ",join(" ","wget",@cmds,@_),"\n");
	if(!open FI,'-|','wget',@cmds,@_) {
		p_tee("Error bring up <wget>: $!\n");
		return undef;
	}
	p_tee("  Execute>\n");
	tee('-'x40,"\n");
	while(<FI>) {
		tee("  " . $_);
	}
	tee('-'x40,"\n");
	close FI;
	return 1;
}
use URI::Escape qw/uri_unescape/;
sub sf_download_file {
	my $pn = shift;
	my $path = shift;
	my $dst = shift;
	my @ms = @_;
	if(!@ms) {
		@ms = (qw/master/);
	}
	my $purl = "https://sourceforge.net/projects/$pn/files/$path";
	my $output = $dst ? "$dst/$path" : $path;
	$output = uri_unescape($output);
	if(-f $output) {
		p_tee("    Ignored> $output [FILE EXISTS]\n");
		return 0;
	}
	if($OPTS{accept}) {
		if($output !~ $OPTS{accept}) {
			p_tee("    Accept>Ignored $output\n");
			return 0;
		}
	}
	if($OPTS{reject}) {
		if($output =~ $OPTS{reject}) {
			p_tee("    Reject>Ignored $output\n");
			return 0;
		}
	}
	foreach my $mn(@ms) {
		p_tee("    Mirror> $mn\n");
		p_tee("    Download> $output\n");
		my @cmd = ("--referer",$purl,"https://$mn.dl.sourceforge.net/project/$pn/$path");
		push @cmd,"-P",$dst if($dst);
		download(@cmd);
		last if(-f $output);
	}
	return 1 if(-f $output);
	return 0;
}

use MyPlace::URLRule::Utils qw/get_url/;

sub sf_download_dir {
	my $purl = shift;
	p_tee("      URL> $purl\n");
	my $html = get_url($purl,'-v');
	my @dirs;
	my @files;
	while($html =~ m/<th[^>]+headers="files_name_h"[^>]*>\s*<a[^>]+href="[^"]*\/(projects\/)([^\/]+)(\/files\/)([^"]+)"/g) {
		my $nurl = "https://sourceforge.net/$1$2$3$4";
		my $pn = $2;
		my $path = $4;
		if($nurl =~ m/\/$/) {
			if($OPTS{include} and $path !~ $OPTS{include}) {
				p_tee("    Include>Ignored $path\n");
				next;
			}
			if($OPTS{exclude} and $path =~ $OPTS{exclude}) {
				p_tee("    Exclude>Ignored $path\n");
				next;
			}
			push @dirs,$nurl;
		}
		elsif($path =~ m/^(.+)\/download$/) {
			push @files,[$pn,$1];
		}
	}
	my $count = 0;
	if(@files > 0) {
		my $now = 1;
		my $max = @files;
		foreach(@files) {
			p_tee("      Files> [$now/$max] $_->[0]/$_->[1]\n");
			$now++;
			$count += sf_download_file($_->[0],$_->[1],@_);
		}
	}
	if(@dirs > 0) {
		my $now = 1;
		my $max = @dirs;
		foreach(@dirs) {
			p_tee("      Directories> [$now/$max] $_\n");
			$now++;
			$count += sf_download_dir($_,@_);
		}
	}
	return $count;
}

sub sf_download {
	my $path = shift;
	my $purl = "https://sourceforge.net/projects/$path/files/";
	my $count = 0;
	if($OPTS{path}) {
		foreach(split(/\s*,\s*/,$OPTS{path})) {
			s/\/+$//g;
			my $url = $purl . $_ . "/";
			$count += sf_download_dir($url,@_);
		}
	}
	else {
		$count = sf_download_dir($purl,@_);
	}
	return $count;
}

p_tee(join(" ",$0,@OLD_ARGV),"\n");
p_tee("Start\n");
my @ms = $OPTS{mirror} ? split(/\s*,\s*/,$OPTS{mirror}) : sort {int(rand(2)) > 0 ? $a : $b} values %MIRRORS;
my @projects;
my @appends;
foreach(@ARGV) {
	if(@appends) {
		push @appends,$_;
	}
	elsif(index($_,'-') == 0) {
		push @appends,$_;
	}
	else {
		push @projects,$_;
	}
}


my $count = 0;
foreach my $pn(@projects) {
	my $dst = $OPTS{dest} ? $OPTS{dest} : 'sf_' . $pn;
	p_tee("  Project> $pn\n");
	p_tee("Directory> $dst\n");
	clean($dst);
	$count += sf_download($pn,$dst,@ms);
}
p_tee("    > $count files downloaded\n");
p_tee("Stop\n",'-'x80,"\n\n");
$TEE->close();




__END__

=pod

=head1  NAME

sf_download - Downloader for sourceforge.net files

=head1  SYNOPSIS

sf_download [options] ...

	sf_download xstbasic --mirror iweb
	sf_download xstbasic xst --mirror jaist,iweb

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

    2015-12-06 00:47  xiaoranzzz  <xiaoranzzz@MyPlace>
        
        * file created.

=head1  AUTHOR

xiaoranzzz <xiaoranzzz@MyPlace>

=cut

#       vim:filetype=perl
