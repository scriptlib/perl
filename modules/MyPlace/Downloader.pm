#!/usr/bin/perl -w
package MyPlace::Downloader;
BEGIN {
    require Exporter;
    our ($VERSION,@ISA,@EXPORT,@EXPORT_OK,%EXPORT_TAGS);
    $VERSION        = 1.00;
    @ISA            = qw(Exporter);
    @EXPORT         = qw();
    @EXPORT_OK      = qw();
}
use strict;
use warnings;
use base 'MyPlace::Program';


sub OPTIONS {qw/
	help|h|? 
	manual|man
	quiet
	history|hist
	overwrite
	force|f
	touch
	markdone
	no-download
	output|saveas|o=s
	max-time|mt=i
	connect-timeout|ct=i
/;}

my %EXPS = (
	"bdhd"=>'^(bdhd:\/\/.*\|)([^\|]+?)(\|?)$',
	'ed2k'=>'^(ed2k:\/\/\|file\|)([^\|]+)(\|.*)$',
	'http'=>'^(http:\/\/.*\/)([^\/]+)$',
	'qvod'=>'^(qvod:\/\/.*\|)([^\|]+?)(\|?)$',
	'torrent'=>'^torrent:\/\/([A-Za-z0-9]+)\|?(.+)$',
	'magnet'=>'^(magnet:\?[^\t]+)',
);

my %DOWNLOADERS = (
	'Vlook'=>{
		'TEST'=>'^(?:http:\/\/|http:\/\/[^\.]+\.)vlook\.cn\/.*\/qs\/',
	},
	'Weishi'=>{
		'TEST'=>'^http:\/\/[^\.]+\.weishi\.com\/.*downloadVideo\.php',
	},
	'Weibo'=>{
		'TEST'=>'^http:\/\/video\.weibo\.com\/',
	},
	'Xiaoying'=>{
		'TEST'=>'^http:\/\/xiaoying.tv\/v\/',
	},
	'HLS'=>{
		'TEST'=>'^hls:\/\/',
	},
	'Yiqi'=>{
		'TEST'=>'^http:\/\/yiqihdl.*\.flv$',
	}

);

my $BLOCKED_URLS = qr/vlook\.cn\/video\/high\/[^\/]+\.mp4$/;

sub extname {
	my $filename = shift;
	return "" unless($filename);
	if($filename =~ m/\.([^\.\/\|]+)$/) {
		return $1;
	}
	return "";
}

sub normalize {
	local $_ = $_[0];
	if($_) {
		s/[\?\*:\\\/]/ /g;
	}
	return $_;
}

sub save_weipai {
	my $self = shift;
	my $url = shift;
	my $filename = shift;
	my @prog = ('download_weipai_video');
	if($self->{OPTS}->{'no-download'}) {
		push @prog,"--no-download";
	}
	push @prog,'--hist' if($self->{OPTS}->{'history'});
	push @prog,('--mtm',@_,'--',$url);
	push @prog,$filename if($filename);
	my $r = system(@prog);
	$r = $r>>8 if(($r != 0) and $r != 2);
	return $r;
}

sub save_vlook {
	my $self = shift;
	my $url = shift;
	my $filename = shift;

}

sub save_http_post {
	my $self = shift;
	my $url = shift;
	my $data = shift;
	my $filename = shift;
	my @opts = @_;
	if($url =~ m/^([^\t]+)\t(.+)$/) {
		$url = $1;
		$filename = $filename || $2;
	}
	if($url !~ m/^(?:http|https|ftp):\/\//) {
		$url = 'http://' . $url;
	}
	if($url =~ m/^([^\?]+)\?(.+)$/) {
		$url = $1;
		push @opts, '--post', $2;
	}
	return $self->save_http($url,$filename || '',@opts);
}

sub file_exists {
	my $self = shift;
	my $url = shift;
	my $filename = shift;
	return unless($filename);
	return if($self->{OPTS}->{force});
	return if($self->{OPTS}->{overwrite});
	if(-f $filename) {
		$self->print_warn("Ignored <$url>\n\tFile exists: $filename\n");
		$self->{LAST_EXIT} = $self->EXIT_CODE("OK");
		return 1;
	}
	else {
		return undef;
	}
}

sub save_http {
	my $self = shift;
	my $url = shift;
	my $filename = shift;
	my @opts = @_;
	push @opts,'--url',$url;
	foreach(qw/max-time connect-timeout/) {
		if($self->{OPTS}->{$_}) {
			push @opts,'--' . $_,$self->{OPTS}->{$_};
		}
	}
	if($filename) {
		return $self->{LAST_EXIT} if($self->file_exists($url,$filename));
		push @opts,'--saveas',$filename if($filename);
	}
	if($url =~ m/:\/\/mtl.ttsqgs.com/) {
		push @opts,"--refurl","https://www.meitulu.com/item/12345.html";
	}
	my $r = system('download',@opts);
	$r = $r>>8 if(($r != 0) and $r != 2);
	return $r;
}


sub file_open {
	my $self = shift;
	my $filename = shift;
	my $mode = shift;
	my $FH;
	if(open $FH,$mode,$filename) {
		return $FH;
	}
	return undef;
}

sub save_file {
	my $self = shift;
	my ($link,$filename) = @_;
	$filename = normalize($filename);
	if($self->file_exists($link,$filename)) {
		return $self->{LAST_EXIT};
	}
	$self->print_msg("Write file: $filename\n");
	my $r = system('mv','--',$link,$filename);
	if($r == 0) {
		return $self->EXIT_CODE('OK');
	}
	elsif($r) {
		return $r;
	}
	else {
		return $self->EXIT_CODE('ERROR');
	}
}


sub save_bdhd {
	my $self = shift;
	my %OPTS = %{$self->{OPTS}};
	my $link = shift;
	my $filename = shift;
	$link = lc($link);
	if(!$filename) {
		foreach my $p (qw/bdhd ed2k/) {
			local $_ = $EXPS{$p};
			if($link =~ m/$_/) {
				$filename = "$2.$p";
				$filename = normalize($filename);
				last;
			}
		}
	}
	else {
		$filename = normalize($filename);
		foreach my $p (qw/bdhd ed2k/) {
			local $_ = $EXPS{$p};
			if($link =~ m/$_/) {
				$link = $1 . $filename . $3;
				$filename = "$filename.$p";
				last;
			}
		}
	}
	$filename =~ s/\.bdhd$//;
	if($link && $filename) {
		$filename = $filename . ".bsed";
		if($self->file_exists($link,$filename)) {
			return $self->{LAST_EXIT};
		}
		$self->print_msg("Write file:$filename\n");
		my $FH = $self->file_open($filename,">:utf8");
		if(!$FH) {
			$self->print_err("Error open file: $filename\n");
			return $self->EXIT_CODE("ERROR");
		}
		print $FH 
<<"EOF";
{
	"bsed":{
		"version":"1,19,0,195",
		"seeds_href":{"bdhd":"$link"}
	}
}
EOF
		close $FH;
		return $self->EXIT_CODE("OK");
	}
	else {
		$self->print_err("Error, No filename specified for: $link\n");
		return $self->EXIT_CODE("ERROR");
	}
}

sub save_qvod {
	my $self = shift;
	my %OPTS = %{$self->{OPTS}};
	my $link = shift;
	my $filename = shift;
	$link = lc($link);
	if(!$filename) {
		foreach my $p (qw/qvod bdhd ed2k http/) {
			local $_ = $EXPS{$p};
			if($link =~ m/$_/) {
				$filename = "$2.$p";
				last;
			}
		}
		$filename = normalize($filename) if($filename);
	}
	else {
		$filename = normalize($filename);
		foreach my $p (qw/qvod bdhd ed2k/) {
			local $_ = $EXPS{$p};
			if($link =~ m/$_/) {
				$link = "$1$filename$3";
				$filename = "$filename.$p";
				last;
			}
		}
	}
	$filename =~ s/\.qvod$//;
	if($link && $filename) {
		return $self->{LAST_EXIT} if($self->file_exists($link,$filename));
		$self->print_msg("Write file:$filename\n");
		my $FH = $self->file_open($filename,">:utf8");
		if(!$FH) {
			$self->print_err("Error open file: $filename\n");
			return $self->EXIT_CODE("ERROR");
		}
		print $FH 
<<"EOF";
<qsed version="3.5.0.61"><entry>
<ref href="$link" />
</entry></qsed>
EOF
		close $FH;
		return $self->EXIT_CODE("OK");
	}
}

sub save_data {
	my $self = shift;
	my %OPTS = %{$self->{OPTS}};
	my $data=shift;
	my $filename = shift;
	return unless($filename);
	$data =~ s/(?:\0|\\n)/\n/g;
	return $self->{LAST_EXIT} if($self->file_exists('<DATA>',$filename));
		$self->print_msg("Write file:$filename\n");
		my $FH = $self->file_open($filename,">:raw");
		if(!$FH) {
			$self->print_err("Error open file: $filename\n");
			return $self->EXIT_CODE("ERROR");
		}
	print $FH $data;
	close $FH;
	return $self->EXIT_CODE("OK");
}

sub save_torrent {
	my $self = shift;
	my $hash = shift;
	my $title = shift;
	require MyPlace::Program::DownloadTorrent;
	my $r;
	if($title) {
		$r = MyPlace::Program::DownloadTorrent::download_torrent($hash,normalize($title));
	}
	else {
		$r = MyPlace::Program::DownloadTorrent::download_torrent($hash);
	}
	return $r;
	if($r == 0) {
		return $self->EXIT_CODE("OK");
	}
	elsif($r) {
		return $r;
	}
	else {
		return $self->EXIT_CODE("ERROR");
	}
}

use Cwd qw/getcwd/;
sub download {
	my $self = shift;
	my $line = shift;
	my @opts = @_;
	$_ = $line;
	my $filename = $_;
	my $wd;
	my $KWD;
	my $exit;
	#$self->print_msg("DOWNLOAD: $line\n");
	if(!$_) {
		return $self->EXIT_CODE('IGNORED');
	}
	if(index($_,"\t")<1) {
		my $sidx = index($_,"    ");
		if($sidx > 1) {
			$_ = substr($_,0,$sidx) . "\t" . substr($_,$sidx+4);
		}
	}
	elsif(m/^(.+?\s*\t\s*([^\t]+))\s*\t\s*([^\t]+)$/) {
		$_ = $1;
		$filename = $2;
		$wd = $3;
		$KWD = getcwd;
	}
	elsif(m/^.+\s*\t\s*(.+)$/) {
		$filename = $1;
	}
	$filename =~ s/.*[\/\\]+//;
	if($wd) {
		mkdir $wd unless(-d $wd);
		if(!chdir $wd) {
			print STDERR "Error change directory: $wd!\n";
			return $self->EXIT_CODE("ERROR");
		}
		else {
			$self->print_msg("Change directory: $wd\n");
			if($self->{mtm}) {
				$self->{saved_prompt} = $self->{mtm}->get_prompt;
				$self->{mtm}->set_prompt($self->{saved_prompt} . ":" . $wd);
			}
		}
	}
	if(-f "files.lst" and open FI,'<',"files.lst") {
		foreach(<FI>) {
			chomp;
			if($_ eq $filename) {
				close FI;
				print STDERR "Ignored: \"$filename\" in FILES.LST\n"; 
				return $self->EXIT_CODE("IGNORED");
			}
		}
		close FI;
	}
	if($self->{OPTS}->{touch}) {
		$self->print_msg("[Touch] $filename\n");
		system("touch","--",$filename);
		$exit = $self->EXIT_CODE("DEBUG");
	}
	elsif($self->{OPTS}->{markdone}) {
		if(-f $filename) {
			$self->print_msg("[Mark done] $filename\n");
			$exit = $self->EXIT_CODE("IGNORED");
		}
		else {
			$self->print_msg("[Not exists] $filename\n");
			$exit = $self->EXIT_CODE("UNKNOWN");
		}
	}

	foreach my $dld(keys %DOWNLOADERS) {
		if(m/$DOWNLOADERS{$dld}->{'TEST'}/) {
			my @args;
			push @args,$1 if($1);
			push @args,$2 if($2);
			push @args,$3 if($3);
			push @args,$4 if($4);
			my $package = $DOWNLOADERS{$dld}->{PACKAGE} || ('MyPlace::Downloader::' . ($DOWNLOADERS{$dld}->{NAME} || $dld));
#			print STDERR "Downloader> import downloader [$dld <$package>]\n";
			eval "require $package;";
			print STDERR "$@\n" if($@);
			my $dl = bless {OPTS=>$self->{OPTS}},$package;
			$exit = $dl->download($_,@args);
			last;
		}
	}

	if(defined $exit) {
	}
	elsif(!$_) {
		$exit = 1;
	}
	elsif($_ =~ $BLOCKED_URLS) {
		print STDERR "Error url blocked: $_\n";
		$exit = $self->EXIT_CODE("ERROR");
	}
	elsif(m/^post:\/\/(.+)$/) {
		$exit = $self->save_http_post($1);
	}
	elsif(m/^qvod:(.+)\t(.+)$/) {
		$exit = $self->save_qvod($1,$2);
	}
	elsif(m/^qvod:(.+)$/) {
		$exit = $self->save_qvod($1);
	}
	elsif(m/^bdhd:(.+)\t(.+)$/) {
		$exit = $self->save_bdhd($1,$2);
	}
	elsif(m/^bdhd:(.+)$/) {
		$exit = $self->save_bdhd($1);
	}
	elsif(m/^(ed2k:\/\/.+)\t(.+)$/) {
		$exit = $self->save_bhdh($1,$2);
	}
	elsif(m/^(ed2k:\/\/.+)$/) {
		$exit = $self->save_bhdh($1);
	}
	elsif(m/^(http:\/\/[^\/]*(?:weipai\.cn|oldvideo\.qiniudn\.com)\/.*)\t(.+)$/) {
		$exit = $self->save_weipai($1,$2);
	}
	elsif(m/^http:\/\/[^\/]*(?:weipai\.cn|oldvideo\.qiniudn\.com)\/.*/) {
		$exit = $self->save_weipai($_);
	}
	elsif(m/^(https?:\/\/.+)\t(.+)$/) {
		$exit = $self->save_http($1,$2);
	}
	elsif(m/^(https?:\/\/.+)$/) {
		$exit = $self->save_http($1);
	}
	elsif(m/^:?(\/\/.+)\t(.+)$/) {
		$exit = $self->save_http("http:$1",$2);
	}
	elsif(m/^:?(\/\/.+)$/) {
		$exit = $self->save_http("http:$1");
	}
	elsif(m/^file:\/\/(.+)\t(.+)$/) {
		$exit = $self->save_file($1,$2);
	}
	elsif(m/^file:\/\/(.+)$/) {
		$exit = $self->save_file($1,"./");
	}
	elsif(m/^data:\/\/(.+)\t(.+)$/) {
		$exit = $self->save_data($1,$2);
	}
	elsif(m/$EXPS{torrent}/) {
		$exit = $self->save_torrent($1,$2);
	}
	elsif(m/$EXPS{magnet}\t(.+)$/) {
		$exit = $self->save_torrent($1,$2);
	}
	elsif(m/$EXPS{magnet}/) {
		$exit = $self->save_torrent($1);
	}
	else {
		$self->print_err("Error: URL not supported [$_]\n");
		$exit = $self->EXIT_CODE("ERROR");
	}
	if($KWD) {
		$self->{mtm}->set_prompt($self->{saved_prompt}) if($self->{mtm});
		chdir $KWD;
	}
	return $exit;
}

 

sub MAIN {
	my $self = shift;
	my $OPTS = shift;
	$self->{OPTS} = $OPTS;
	my @lines = @_;
	if(!@lines) {
		while(<STDIN>) {
			chomp;
			push @lines,$_;
		}
	}
	if((scalar(@lines) == 1) and $self->{OPTS}->{output}) {
		$lines[0] .= "\t" . $self->{OPTS}->{output};
	}
	my $exit;
	foreach my $url (@lines) {
		if($url =~ m/^#([^:]+?)\s*:\s*(.*)$/) {
			$self->{source}->{$1} = $2;
			next;
		}
		$exit = $self->download($url);
	}
	return $exit;
}

return 1 if caller;
my $PROGRAM = new MyPlace::Downloader;
exit $PROGRAM->execute(@ARGV);

