#!/usr/bin/perl -w
package MyPlace::Weipai::Downloader;
use strict;
use warnings;
BEGIN {
    require Exporter;
    our ($VERSION,@ISA,@EXPORT,@EXPORT_OK,%EXPORT_TAGS);
    $VERSION        = 1.00;
    @ISA            = qw(Exporter);
    @EXPORT         = qw(&download);
    @EXPORT_OK      = qw(&download);
}
use base 'MyPlace::Program';
use MyPlace::Program::Download;
use MyPlace::Weipai qw/get_url build_url get_blog_id/;

my $DOWNLOADER;
my %VIDEO_TYPE = (
	'.mp4'=>'/500k.mp4',
	'.mov'=>'.mov',
	'.flv'=>'.flv',
	'.ts'=>'./500k.ts',
);



my @URL_RECORD;
my %URLID;

my $cookie = $ENV{HOME} . "/.cookies.weipai.dat";
sub init {
	$DOWNLOADER = new MyPlace::Program::Download('--cookie',$cookie);
	@URL_RECORD = ();
	print STDERR "Opening http://weipai.cn/...";
	if($DOWNLOADER->execute('--url','http://weipai.cn','--quiet','--test') == 0) {
		print STDERR "  [OK]\n";
	}
	else {
		print STDERR "  [FAILED]\n";
	}
}

sub get_url_id {
	my $_ = shift;
	my $ext = shift;
	if(!$ext) {
		$ext = $_;
	}
	$ext =~ s/^.*\///;
	$ext =~ s/^.*\.//;
	my $id = $_;
	my $idexp = '[A-Za-z0-9\-]+';
	if(m{/\d{6}/\d\d/\d\d/($idexp)}) {
		$id = $1;
	}
	elsif(m/weipai.cn\/video\/uuid\/($idexp)/) {
		$id = $1;
	}
	elsif(m/weipai.cn\/video\/($idexp)/) {
		$id = $1;
	}
	return "$ext:$id";
}

sub hist_check_url {
	my $url = shift;
	my $basename = shift;
	my $suffixs = shift;
	my $dup = 0;
	if(!@URL_RECORD) {
		if(open FI,'<','URLS.txt') {
			foreach(<FI>) {
				chomp;
				push @URL_RECORD,$_;
				$URLID{get_url_id($_)} = 1;
			}
			close FI;
		}
	}
	return 0 unless($url);
	
	if(!$suffixs) {
		$suffixs = [$url];
	}
	if($URLID{get_url_id($url)}) {
		print STDERR "  Ignored, \"$url\"\n\tRecord in file <URLS.txt>\n";
		return 2;
	}
	foreach my $ext(@$suffixs) {
		if($URLID{get_url_id($url,$ext)}) {
			print STDERR "  Ignored, \"$url\"\n\tRecord in file <URLS.txt>\n";
			return 2;
		}
	}
	return 0;
}

sub hist_add_url {
	my $url = shift;
	push @URL_RECORD,join("\t",$url,@_);
	$URLID{get_url_id($url)} = 1;
}

sub hist_save {
	if(open FO,">","URLS.txt") {
		print FO join("\n",@URL_RECORD),"\n";
		close FO;
	}
	else {
		print STDERR "Error writing URLS.txt: $!\n";
	}
}
sub _parse_suffix {
	my $url = shift;
	my $suffix = shift;
	return $suffix if(ref $suffix);
	my $r;
	if(!$suffix) {
		if($url =~ m/\.jpg$/) {
			$r = [qw/.jpg .mov.3in1.jpg/],
			#.jpg .1.jpg .2.jpg .p.1.jpg .p.2.jpg/];
		}
		elsif($url =~ m/\.m3u8/) {
			$r = [qw/.ts .flv .mov .mp4/];
		}
		elsif($url =~ m/\/video\/[^\/]+$/) {
			$r = [qw/.ts .flv .mov .mp4/];
		}
		else {
			$r = [qw/\/500k.ts/];
			#$r = [qw/\/500k.ts .flv .mov .mp4/];
		}
	}
	else {
		$r = [split(/\s*,\s*/,$suffix)];
	}
	return $r;
}
sub download_urls {
	my $OPTS = shift;
	my $tasks = shift;
	my $hist = shift(@_) || $OPTS->{history};
	my $overwrite = shift(@_) || $OPTS->{overwrite};
	my $suffix = shift(@_) || $OPTS->{suffix};
	if(!($tasks and @{$tasks})) {
		print STDERR "No tasks to download\n";
		return 1;
	}
	my $idx = 0;
	my $count = scalar(@$tasks);
	use Cwd qw/getcwd/;
	my $PWD = getcwd;
	$PWD =~ s/\/+$//;
	$PWD =~ s/^.*\/([^\/]+\/[^\/]+\/[^\/]+)$/$1/;
	print STDERR "\n$PWD/\n";
	print STDERR "\tGet $count task(s) for download ...\n";
	foreach my $task(@$tasks) {
		$idx++;
		my $prom = "[$idx/$count] ";
		print STDERR $prom;
		if(!$task->[0]) {
			print STDERR "No URL specified for task!\n";
			next;
		}
		my @args = _preprocess($OPTS,$task->[0],$task->[1],$suffix);
		if(@args) {
			my($input,$output) = _download(@args);
			if($input) {
				hist_add_url($input,$output);
			}
			else {
			}
		}
	}
	hist_save() if($hist);
	return 0;
}


#sub _preprocess {
#	my $OPTS = shift;
#	my $url = shift;
#	my $basename = shift;
#	my $suffix = shift(@_) || $OPTS->{exts};
#	my $hist = shift(@_) || $OPTS->{history};
#	my $overwrite = shift(@_) || $OPTS->{overwrite};
#	my $mtm = $OPTS->{mtm};
#	
#	my $uuid_url;
#	my $blog_id;
#	if($url =~ m/.*\/\d+\/\d+\/\d+\/([^\/]+)\.(mov|mp4|flv)/) {
#		$blog_id = MyPlace::Weipai::get_blog_id($url);
#	}
#	elsif($url =~ m/\/video\/uuid\/([^?#&]+)/) {
#		$blog_id = MyPlace::Weipai::get_blog_id($1);
#	}
#	if($blog_id) {
#		$uuid_url = $url;
#		$url = 'http://www.weipai.cn/video/' . $blog_id;
#		print STDERR "Video Page => $url\n";
#	}
#
#	if($url =~ m/\.(?:mp4|mov|flv)/) {
#		print STDERR "  Ignored: url type not supported\n";
#		return MyPlace::Program::EXIT_CODE("FAILED");
#	}
#
#	$suffix = _parse_suffix($url,$suffix);
#
#	my $noext = qr/(?:\/500k\.ts|\/500k\.mp4|\.mov\.l\.jpg|\.mov\.3in1\.jpg|\.jpg|\.\d\.jpg|\.mov|\.mp4|\.flv|\.f4v|\.ts)$/o;
#
#	$url =~ s/$noext//;
#	$url =~ s/\/thumbnail\/.*\/video\//\/video\//;
#	if(!$basename) {
#		$basename = $url;
#		$basename =~ s/^.+\/(\d+)\/(\d+)\/(\d+)\/([^\/]+)$/$1$2$3_$4/;
#		$basename =~ s/[\?#].*//;
#	}
#	else {
#		$basename =~ s/$noext//;
#	}
#	$basename =~ s/^.*\///;
#	$basename =~ s/\.m3u8$//;
#	if($hist) {
#		if($uuid_url) {
#			return undef if(hist_check_url($uuid_url,$basename,$suffix));
#		}
#		return undef if(hist_check_url($url,$basename,$suffix));
#	}
#	else {
#		hist_check_url();
#	}
#	my $exts = {};
#	foreach(@$suffix) {
#		if(m/(\.[^\.]+)$/) {
#			$exts->{$_} = $1;
#		}
#	}
#	if(!$overwrite) {
#		my $o_basename = $basename;
#		if($basename =~ m/^(\d+)_(.+)$/) {
#			my $dstr = $1;
#			my $o_name = $2;
#			$dstr =~ s/\d\d$//;
#			$o_basename = $dstr . '_' . $o_name;
#		}
#		my %filelist;
#		if(-f "files.lst" and open FI,'<',"files.lst") {
#				foreach(<FI>) {
#					chomp;
#					$filelist{$_} = 1;
#				}
#				close FI;
#		}
#		foreach(keys %$exts,values %$exts) {
#			if($filelist{$basename . $_}) {
#				print STDERR "  Ignored, File \"$basename" . $_ . "\" in FILES.LST\n";
#				return undef;
#			}
#			elsif($filelist{$o_basename . $_}) {
#				print STDERR "  Ignored, Old file \"$o_basename" . $_ . "\" in FILES.LST\n";
#				return undef;
#			}
#			elsif(-f $basename . $_) {
#				print STDERR "  Ignored, File \"$basename" . $_ . "\" exists\n";
#				return undef;
#			}
#			elsif( -f $o_basename . $_) {
#				print STDERR "  Ignored, Old file \"$o_basename" . $_ . "\" exists\n";
#				return undef;
#			}
#		}
#	}
#	if($mtm and -f '.mtm/done.txt' and open FI,'<','.mtm/done.txt') {
#		print STDERR "  Checking MTM database <done.txt> ... ";
#		my %DONE;
#		foreach (<FI>) {
#			chomp;
#			$DONE{get_url_id($_)} = 1;
#		}
#		close FI;
#		if(%DONE) {
#			foreach my $suf(@$suffix) {
#				my $ext = $exts->{$suf};
#				my $input = $url . $suf;
#				if($DONE{get_url_id($input,$ext)}) {
#					print STDERR "[EXIST]\n  Ignored, url recored in <.mtm/done.txt>\n   $input\n";
#					return undef;
#				}
#			}
#		}
#		print STDERR "[OK]\n";
#	}
#	$url =~ s/aliv3\.weipai\.cn/aliv\.weipai\.cn/;
#	$url =~ s/oldvideo\.qiniudn\.com/v.weipai.cn/;
#	return $url,$basename,$suffix,$exts;
#}
sub _preprocess {
	my $OPTS = shift;
	my $url = shift;
	my $basename = shift;
	my $suffix = shift(@_) || $OPTS->{exts};
	my $hist = shift(@_) || $OPTS->{history};
	my $overwrite = shift(@_) || $OPTS->{overwrite};
	my $mtm = $OPTS->{mtm};

	my $nurl = $url;
	if($url =~ m/(.*\/\d+\/\d+\/\d+\/)([^\/]+)\/500k\.ts$/) {
		$nurl = $1 . $2 . ".m3u8";
	}
	elsif($url =~ m/(.*\/\d+\/\d+\/\d+\/)([^\/]+)\.(mov|mp4|flv)/) {
		$nurl = $1 . $2 . ".m3u8";
	}
	elsif($url =~ m/\/video\/uuid\/([^?#&]+)/) {
		$nurl = undef;
	}
	elsif($url =~ m/\/video\/[^\/]+$/) {
		$nurl = undef;
	}

	if(!$nurl) {
		print STDERR "  Ignored: url type not supported\n";
		return MyPlace::Program::EXIT_CODE("FAILED");
	}
	
	$url = $nurl;
	$suffix = _parse_suffix($url,$suffix);

	my $noext = qr/(?:\/500k\.ts|\/500k\.mp4|\.mov\.l\.jpg|\.mov\.3in1\.jpg|\.jpg|\.\d\.jpg|\.mov|\.mp4|\.flv|\.f4v|\.ts\.png)$/o;

	$url =~ s/$noext//;
	$url =~ s/\/thumbnail\/.*\/video\//\/video\//;
	if(!$basename) {
		$basename = $url;
		$basename =~ s/^.+\/(\d+)\/(\d+)\/(\d+)\/([^\/]+)$/$1$2$3_$4/;
		$basename =~ s/[\?#].*//;
	}
	$basename =~ s/^.*\///;
	$basename =~ s/\?.+$//;
	$basename =~ s/\.m3u8$//;
		$basename =~ s/$noext//;
	if($hist) {
		return undef if(hist_check_url($url,$basename,$suffix));
	}
	else {
		hist_check_url();
	}
	my $exts = {};
	foreach(@$suffix) {
		if(m/(\.[^\.]+)$/) {
			$exts->{$_} = $1;
		}
	}
	#$exts->{".jpg"} = ".png";
	if(!$overwrite) {
		my $o_basename = $basename;
		if($basename =~ m/^(\d+)_(.+)$/) {
			my $dstr = $1;
			my $o_name = $2;
			$dstr =~ s/\d\d$//;
			$o_basename = $dstr . '_' . $o_name;
		}
		my %filelist;
		if(-f "files.lst" and open FI,'<',"files.lst") {
				foreach(<FI>) {
					chomp;
					$filelist{$_} = 1;
				}
				close FI;
		}
		foreach(keys %$exts,values %$exts) {
			if($filelist{$basename . $_}) {
				print STDERR "  Ignored, File \"$basename" . $_ . "\" in FILES.LST\n";
				return undef;
			}
			elsif($filelist{$o_basename . $_}) {
				print STDERR "  Ignored, Old file \"$o_basename" . $_ . "\" in FILES.LST\n";
				return undef;
			}
			elsif(-f $basename . $_) {
				print STDERR "  Ignored, File \"$basename" . $_ . "\" exists\n";
				return undef;
			}
			elsif( -f $o_basename . $_) {
				print STDERR "  Ignored, Old file \"$o_basename" . $_ . "\" exists\n";
				return undef;
			}
		}
	}
	if($mtm and -f '.mtm/done.txt' and open FI,'<','.mtm/done.txt') {
		print STDERR "  Checking MTM database <done.txt> ... ";
		my %DONE;
		foreach (<FI>) {
			chomp;
			$DONE{get_url_id($_)} = 1;
		}
		close FI;
		if(%DONE) {
			foreach my $suf(@$suffix) {
				my $ext = $exts->{$suf};
				my $input = $url . $suf;
				if($DONE{get_url_id($input,$ext)}) {
					print STDERR "[EXIST]\n  Ignored, url recored in <.mtm/done.txt>\n   $input\n";
					return MyPlace::Program::EXIT_CODE("OK");
				}
			}
		}
		print STDERR "[OK]\n";
	}
	$url =~ s/aliv3\.weipai\.cn/aliv\.weipai\.cn/;
	$url =~ s/oldvideo\.qiniudn\.com/v.weipai.cn/;
	return $url,$basename,$suffix,$exts;
}

sub _download {
	my $url = shift;
	my $basename = shift;
	my $suffix = shift;
	my $exts = shift;
	$DOWNLOADER = $DOWNLOADER || new MyPlace::Program::Download;
	foreach my $suf(@$suffix) {
		my $ext = $exts->{$suf};
		my $input = $url . $suf;
		my $output = $basename . $ext;
		$DOWNLOADER->execute("--url",$input,"--saveas",$output,"--maxtry",2);
		if(-f $output) {
			system('touch','-c','-h','../');
			system('touch','-c','-h','../../');
			return $input,$output;
		}
	}
	return undef;
}
sub get_video_url {
	my $url = shift;
	my $vid = $url;
	$vid =~ s/.*\/video\///;
	$vid =~ s/[\?#].*//;
	$vid =~ s/\/.*//;
	
	#my $data = get_url(build_url('play',$vid),'-v');
	my $data = get_url("http://share.weipai.cn/video/play/id/$vid/type/theater/source/undefined",'-v');
	die($data);
	my $playurl;
	if($data =~ m/"video_url"\s*:\s*"([^"]+)/) {
		$playurl = $1;
	}
	elsif($data =~ m/'video_url'\s*:\s*'([^']+)/) {
		$playurl = $1;
	}
	elsif($data =~ m/videoUrl=([^&]+)/) {
		$playurl = $1;
	}
	else {
		print STDERR "Error retriving info: $url\n";
		return undef;
	}
	$playurl =~ s/\\//g;
	return $playurl;
}

sub _download_video {
	my $url = shift;
	my $vid = $url;
	$vid =~ s/.*\/video\///;
	$vid =~ s/[\?#].*//;
	$vid =~ s/\/.*//;
	
	my $playurl = get_video_url($url);
	if($playurl) {
	}
	else {
		print STDERR "Error retriving info: $url\n";
		return undef;
	}
	$playurl =~ s/\\//g;
	my($input,$output) = _download_m3u8($playurl,@_);
	if($input and $output) {
			&hist_add_url($url,$output);
			&hist_save();
	}
	return $input,$output;
#	$DOWNLOADER = $DOWNLOADER || new MyPlace::Program::Download;
}

sub _download_m3u8 {
	my ($url,$basename,$suffix,$exts) = @_;
	$DOWNLOADER = $DOWNLOADER || new MyPlace::Program::Download;
	
	my $f_m3u = $basename . ".m3u8";
	
	if(!-f $f_m3u) {
		$DOWNLOADER->execute("--url",$url,"--saveas",$f_m3u,"--maxtry",2);
		return undef,undef unless(-f $f_m3u);
	}
	if(!open FI,"<:utf8",$f_m3u) {
		print STDERR "Error opening file $f_m3u: $!\n";
		return undef,undef;
	}
	my @urls;
	while(<FI>) {
		chomp;
		push @urls,$_ if(m/^http:\/\//);
	}
	close FI;
	unlink $f_m3u;
	my $idx = 0;
	my $count = @urls;
	my @data;
	my @files;
	if($count < 1) {
		 return undef,undef;
	}
	foreach(@urls) {
		$idx++;
		my $output = $basename . '_' .  $idx . '.ts';
		print STDERR "  [$idx/$count] ";
		$DOWNLOADER->execute("--url",$_,"--saveas",$output,"--maxtry",4);
		if(-f $output) {
			open FI,'<:raw',$output;
			push @data,<FI>;
			close FI;
			push @files,$output;
		}
		else {
			print STDERR "Download playlist falied\n";
			return undef,$output;
		}
	}
	if(@data) {
		open FO,">:raw",$basename . ".ts" or return;
		print FO @data;
		close FO;
		print STDERR "Playlist saved to : $basename" . ".ts\n";
		unlink @files;
	}
	return $url,$basename . ".ts";
}

sub download {
	#$OPTS->{history},$OPTS->{overwrite},$OPTS->{exts}
	my $OPTS = shift;
	my @args = _preprocess($OPTS,@_);
	
	my ($exit,$input,$output);
	

	if(!@args) {
		$exit = 12;
	}
	elsif(!defined $args[0]) {
		$exit = MyPlace::Program::EXIT_CODE("UNKNOWN");

	}
	elsif($OPTS->{"no-download"}) {
		$exit = MyPlace::Program::EXIT_CODE("UNKNOWN");
	}
	elsif($args[0] =~ /^\d+$/) {
		$exit = $args[0];
	}
	return $exit if(defined $exit);

	use Cwd qw/getcwd/;
	my $PWD = getcwd;
	$PWD =~ s/\/+$//;
	$PWD =~ s/^.*\/([^\/]+\/[^\/]+\/[^\/]+)$/$1/;
	print STDERR "\n$PWD/";
	if($args[0] =~ m/weipai\.cn\/video\/[^\/]+$/) {
		print STDERR "\n";
		my $n_url = get_video_url($args[0]);
		return 11 unless($n_url);
		print STDERR " => $n_url\n";
		my $n_basename = $args[1] || undef;
		$exit = download($OPTS,$n_url,$n_basename);
		if($exit == 0) {
			$input = $args[0];
			$output = $args[1];
		}
	}
	elsif($args[0] =~ m/\.m3u8/) {
		print STDERR "\n";
		($input,$output) = _download_m3u8(@args);
	}
	else {
		($input,$output) = _download(@args);
	}
	
	if($input and $output) {
		&hist_add_url($input,$output);
		&hist_save();

		#SUCCESSED
		$exit = 0;
	}
	elsif($output) {
		#UNKNOWN / NO-DOWNLOAD
		$exit = MyPlace::Program::EXIT_CODE("UNKNOWN");
	}
	elsif($input) {
		#IGNORED
		$exit = 12;
	}
	else {
		#FAILED;
		$exit = 11;
	}
	return $exit;
}

sub OPTIONS {
	qw/
		help|h|? 
		manual|man
		history|hist
		overwrite|o
		exts:s
		mtm
		no-download
	/;
}

sub USAGE {
	my $self = shift;
	require Pod::Usage;
	Pod::Usage::pod2usage(@_);
	return 0;
}

sub MAIN {
	my $self = shift;
	my $OPTS = shift;
	my @args = @_;
	return download($OPTS,@args);
	#$OPTS->{history},$OPTS->{overwrite},$OPTS->{exts}
	#);
}

return 1 if caller;
my $h = new MyPlace::Weipai::Downloader;
exit $h->execute(@ARGV);

__END__

=pod

=head1  NAME

MyPlace::Weipai::Downloader

=head1  SYNOPSIS

MyPlace::Weipai::Downloader [options...] URL TITLE


=head1  OPTIONS

=over 12

=item B<--history>

Enable tracking history of URL by URLS.txt

=item B<--overwrite>

Overwrite target if file exists

=item B<--exts>

File formats by orders for downloading, e.g. .mov, .mp4, .flv

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

    2014-11-26 00:18  xiaoranzzz  <xiaoranzzz@MyPlace>
        
        * file created.

=head1  AUTHOR

xiaoranzzz <xiaoranzzz@MyPlace>

=cut

#       vim:filetype=perl


