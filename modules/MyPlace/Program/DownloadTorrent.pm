#!/usr/bin/perl -w
package MyPlace::Program::DownloadTorrent;
use strict;
use warnings;
BEGIN {
    require Exporter;
    our ($VERSION,@ISA,@EXPORT,@EXPORT_OK,%EXPORT_TAGS);
    $VERSION        = 1.00;
    @ISA            = qw(Exporter);
    @EXPORT         = qw(&download_torrent);
    @EXPORT_OK      = qw(&download_torrent &download \@SITES);
}
use File::Spec;
use MyPlace::Script::Message;
use MyPlace::Escape qw/js_escape js_unescape/;
use MyPlace::URLRule::Utils qw/get_url/;
use MyPlace::Program::Download;
use base 'MyPlace::Program';

our $DL;
our $VERSION = 'v0.1';
our @OPTIONS = qw/
	help|h|? 
	manual|man
	verbose|v
	log|l
	no-hashdb|nhd
/;


my $VERBOSE;
my $SCRIPTDIR;
my %GLOBAL_OPTIONS;

our @SITES = (
	#http://www.520bt.com/Torrent/:HASH:
	#http://torcache.net/torrent/:HASH:.torrent	
	#http://torrage.ws/torrent/:HASH:.torrent
	#https://torrage.ws/torrent/:HASH:.torrent
	#http://www.sobt5.com/Tool/downbt?info=:HASH:
	#http://www.torrenthound.com/torrent/:HASH:
	#http://torrage.com/torrent/:HASH:.torrent
	#http://zoink.it/torrent/:HASH:.torrent
	#http://www.mp4ba.com/down.php?date=1422367802&hash=:HASH:
	#https://torrentproject.se/torrent/:HASH:.torrent
	#http://torrage.biz/torrent/:HASH:.torrent
	#https://torcache.net/torrent/:HASH:.torrent
	#post://www.torrent.org.cn/download.php?hash=:HASH:
	qw{
		https://itorrents.org/torrent/:HASH:.torrent
		https://www.seedpeer.eu/torrent/:HASH:
	}
);
#@SITES = ( 'post://www.torrent.org.cn/download.php?hash=:HASH:',);
our %SITES2 = (
	'#seedpeer.eu'=>sub {
		my $hash = shift;
		my $url = 'http://www.seedpeer.eu/hash.php?hash=' . $hash;
		my $html = get_url($url,'-v');
		if($html =~ m/href="\/details\/[^\/]+\/([^\/]+)\.html/) {
			my $name = lc($1);
			$name =~ s/\(([^\)]+)\)/$1/g;
			$name =~ s/\[([^\]]+)\]/$1/g;
			$name =~ s/[^a-zA-Z0-9]/_/g;
			$name =~ s/__+/_/g;
			$name =~ s/^_+//;
			$name =~ s/_+$//;
			return 'http://www.seedpeer.eu/download/' . $name . '/' . $hash;
		}
		print STDERR "NO torrent found on seedpeer.eu\n";
		return undef;
	}
);

#%SITES2 = ();

sub error_no {
	return MyPlace::Program::EXIT_CODE(@_);
}

my $HASHDB_FILE = 'HASH.lst';
my %HASHDB;
my $HASHDB_FO;
sub check_hash {
	my $hash = shift;
	my $title = shift;
	my $opts = shift;
	$opts = {} unless($opts);

	if($GLOBAL_OPTIONS{'no-hashdb'}) {
	}
	elsif(!$HASHDB_FO) {
		app_warning("Opening database: <$HASHDB_FILE>\n");
		my $count = 0;
		if(open FI,'<',$HASHDB_FILE) {
			foreach(<FI>) {
				chomp;
				next unless($_);
				$count++;
				my($k1,$k2) = split(/\s*\t\s*/,$_);
				$HASHDB{$k1} = $k2 || '';
			}
			close FI;
		}
		app_warning("\t$count record read\n");
#		use MyPlace::Data::Dumper;print STDERR (dumpdata(\%HASHDB,'$HASHDB'));
		open $HASHDB_FO,">>",$HASHDB_FILE or warn("Error opening $HASHDB_FILE: $!\n");
	}
	if($opts->{read}) {
		return $HASHDB{$hash};
	}
	elsif($GLOBAL_OPTIONS{'no-hashdb'}) {
		return 1;
	}
	elsif(defined $HASHDB{$hash}) {
		app_message "[HASHDB] $hash => \"$HASHDB{$hash}\"\n";
		return undef;
	}
	elsif($opts->{write}) {
		print $HASHDB_FO $hash, ($title ? "\t$title\n" : "\n");
		return 1;
	}
	else {
		return 1;
	}
}

sub write_hash {
	return check_hash($_[0] || '',$_[1] || '',{write=>1});
}

sub read_hash {
	return check_hash($_[0] || '',$_[1] || '',{read=>1});
}

sub DESTORY {
	close $HASHDB_FO;
}

sub check_type {
	my $output = shift;
	return unless(-f $output);
	my $type = `file -b --mime-type -- "$output"`;
	chomp $type;
	if($type =~ m/torrent|octet-stream/) {
		return 1,$type;
	}
	return undef,$type;
}

sub normalize {
	local $_ = $_[0];
	if($_) {
		$_ = js_unescape($_) if(m/%[^%]+/);#%[^%]+%[^%]+/);
		s/_*[\?\*\/:\\+]_*/_/g;
		s/_*-_*/_/g;
		s/__+/_/g;
	}
	return $_;
}

my $MAX_PATH = 206;
sub short_filename {
	local $_ = shift;
	if($_) {
		if(length($_) > $MAX_PATH) {
			app_warning("Filename too long, cut it\n");
			$_ = substr($_,0,$MAX_PATH);
			print STDERR "  =>$_\n";
		}
	}
	return $_;
}
sub download {
	my $output = shift;
	my $URL = shift;
	my $REF = shift(@_) || $URL;
	$DL ||= MyPlace::Program::Download->new();
	
	my $postd = shift;
	if($URL =~ m/^post:\/\/(.+)$/) {
		$URL = $1;
		$postd = "";
		if($URL !~ m/^(?:http:\/\/|https:\/\/|ftp:\/\/)/) {
			$URL = 'http://' . $URL;
		}
		if($URL =~ m/\?([^\?]+)$/) {
			$postd = $1;
		}
	}

	my @OPTS;
	if(defined $postd) {
		push @OPTS,'--post',$postd;
	}

	if($DL->execute(
		'--max-time',300,
		'--connect-timeout',20,
		'--compressed',
		'--maxtry',1,
		"-r",$REF,
		"-u",$URL,
		"-s",$output,
		@OPTS) == 0
	) {
		my ($ok,$type) = check_type($output);
		if($ok) {
			return 1;
		}
		else {
			print STDERR " ($type) ";
			unlink($output);
		}
	}
	return undef;
}

sub download_torrent {
	my $URI = shift;
	my $title = shift;
	my $dest = shift;
	my $filename = shift;

	
	if(!$title and $URI =~ m/^([^\t]+)\t(.+)$/) {
		$URI = $1;
		$title = $2;
	}

	my $hash;

	if($URI =~ m/^([\dA-Za-z]+)$/) {
		$hash = uc($1);
	}
	elsif($URI =~ m/^magnet:\?/i) {
		my $ul = uc($URI);
		if($ul =~ m/^MAGNET:\?.*XT=URN:BTIH:([\dA-Z]+)/) {
			$hash = $1;
		}
		if((!$title) and $URI =~ m/&dn=([^&]+)/) {
			$title = $1;
		}
	}
	else {
		app_error "No HASH information found in $URI\n";
		return error_no("ERROR");
	}

	if(!check_hash($hash)) {
		app_warning "Ignored, [$hash] exists in DB <$HASHDB_FILE>\n";
		return error_no("IGNORED");
	}

	my $output = "";
	
	if(!$filename) {
		$title = read_hash($hash) unless($title);
		if(!$title) {
			my $getor = File::Spec->catfile($SCRIPTDIR,"gettorrent_title.pl");
			$getor =  File::Spec->catfile($SCRIPTDIR,"gettorrent_title") unless(-f $getor);
			if(-f $getor) {
				$title = `perl "$getor" "$hash"`;
			}	
			else {
				$title = `gettorrent_title "$hash"`
			}
			if($title) {
				chomp($title);
			}
		}
		$filename = ($title ? short_filename(normalize($title)) . "_" : "") . $hash;
	}
	else {
		$filename =~ s/\.torrent$//gi;
		$filename = short_filename($filename);
	}
	$filename =~ s/\[?email&#160;protected\]?//g;
	$filename =~ s/[\\\?\:\>\<\/\*]+\s*//g;
	
	#$filename = short_filename($filename);
	if($dest) {
		$output = File::Spec->catfile($dest,$filename);
	}
	else {
		$output = $filename;
	}

	#app_message "\n$URI\n";
	app_message2 "File name length: " . length("$filename") . "\n";
	app_message2 "Save torrent file:\n  =>$filename.torrent\n";
	$output .= ".torrent";
	my $exit;
	if(check_type($output)) {
		app_warning "Error, File already downloaded, Ignored\n";
		write_hash($hash,$title);
		$exit =  error_no("IGNORED");
	}
	if(!defined $exit) {
		foreach my $site (@SITES) {
			next if($site =~ m/^#/);
			my $sitename = $site;
			if($site =~ m/:\/\/([^\/]+)/) {
				$sitename = $1;
			}
			my $url = $site;
			$url =~ s/:HASH:/$hash/g;
	#		print STDERR "<= $url\n";
			print STDERR "  Try [$sitename] ... ";
			if(download($output,$url)) {
				color_print('GREEN',"  [OK]\n");
				write_hash($hash,"$title\t$url");
				$exit = error_no("OK");
				last;
			}
			else {
				color_print('RED',"  [FAILED]\n");
			}
		}
	}
	if(!defined $exit) {
		foreach my $sitename(keys %SITES2) {
			next if($sitename =~ m/^#/);
			my $url = $SITES2{$sitename}($hash);
			next unless($url);
			print STDERR "  Try [$sitename]$url ... ";
			if(download($output,$url)) {
				color_print('GREEN',"  [OK]\n");
				write_hash($hash,"$title\t$url");
				$exit = error_no("OK");
				last;
			}
			else {
				color_print('RED',"  [FAILED]\n");
			}
			
		}
	}
	if(!defined $exit){
		if($URI =~ m/^(magnet:[^\t]+)/) {
			$URI =~ s/&amp;/&/g;
			app_message2 "Save magnet uri:\n  =>$filename.txt\n";
			if(open FO,">:utf8",$output . ".txt") {
				print FO $URI,"\n";
				close FO;
				print STDERR "[OK, magnet only]\n";
				$exit = error_no("FAILED");
			}
			else {
				print STDERR "Error:$!\n";
				$exit = error_no("FAILED");
			}
		}
		else {
			color_print('RED',"[Failed]\n\n");
			$exit = error_no("FAILED");
		}
	}
	return $exit;
}

sub USAGE {
	my $self = shift;
	require Pod::Usage;
	Pod::Usage::pod2usage('-input',__FILE__,@_);
	return 0;
}

sub OPTIONS {
	return @OPTIONS;
}

sub MAIN {
	my $self = shift;
	my $OPTS = shift;
	%GLOBAL_OPTIONS = %$OPTS;
	my @argv = @_;
	$VERBOSE = $OPTS->{'verbose'};
	$SCRIPTDIR = $0;
	$SCRIPTDIR =~ s/[\/\\]+[^\/\\]+$//;
	if(!@argv) {
		my @LINES;
		my $count;
		my $index;
		while(<STDIN>) {
			chomp;
			push @LINES,$_ if($_);
		}
		$count = @LINES;
		foreach my $line(@LINES) {
			$index++;
			print STDERR "TASK $index/$count: \n";
			my @args = split(/\s*\t\s*/,$line);
			download_torrent(@args);
		}
	}
	else {
		return download_torrent(@argv);
	}
}

return 1 if caller;
my $PROGRAM = new MyPlace::Program::DownloadTorrent;
exit $PROGRAM->execute(@ARGV);



__END__

=pod

=head1  NAME

download_torrent - Bittorrent torrent file downloader

=head1 SYNOPSIS

download_torrent [options] <hash value|magnet URI> <title>

	download_torrent ADFDSFEWAFDSAFDSAFDGREARAGFDSFD2214DAFDSA sorrynoname

=head1  OPTIONS

=over 12

=item B<--version>

Print version infomation.

=item B<-h>,B<--help>

Print a brief help message and exits.

=item B<--manual>,B<--man>

View application manual

=back

=head1  DESCRIPTION

Bittorrent torrent files downloader

=head1  CHANGELOG

    2014-06-18 00:07  xiaoranzzz  <xiaoranzzz@MyPlace>
        
        * file created.

=head1  AUTHOR

xiaoranzzz <xiaoranzzz@MyPlace>

=cut

#       vim:filetype=perl

