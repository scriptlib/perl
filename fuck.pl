#!/usr/bin/perl -w
# $Id$
package MyPlace::Script::fuck;
use strict;

our $VERSION = 'v0.1';
my @OPTIONS = qw/
	help|h|? 
	manual|man
	source|directory|d=s
	update|renew|rebuild|u
	group|g=s
	videos|c=s
	video-only
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
my $OS = 'linux';
my $OSTYPE = $^O;
if(!$OSTYPE) {
	$OS = 'windows';
}
elsif($OSTYPE eq 'cygwin') {
	$OS = 'cygwin';
}
elsif($OS =~ m/Windows/i) {
	$OS = 'windows';
}
else {
	$OS = 'linux';
}

my @DEF_DIR = (qw{
	/z/datapool
	/z/datapool2
	/myplace/appdata/dp
	/u/datapool
	/service/Temp/
});
my %GROUPS = (
	'play'=>{},
	'fuck'=>{},
);
my $PLAYGROUP = $GROUPS{play};
my $FUCKGROUP = $GROUPS{fuck};

$PLAYGROUP->{"NAMES"} = ['by hand',qw{
	fuckher
	babes
	avstars
	babes1
	babes2
	babes3
	camgirls
	webcam
	todo/taskspool/ladies
	},
	'babes#reposter',
	'babes#review',
	'babes#sluts',
];

$PLAYGROUP->{"VIDEOS"} = [qw{
	avstars
	candit
	hotstuffs/all
	leakage
	videos
	},
	'selfie/##NSFW',
	'webcam/##NSFW',
	'clips/##NSFW',
];

$PLAYGROUP->{"VIDOES_SAFE"} = ['tv show',qw{
	movies
	clips
	shows
	webcam
	selfie
}];

$PLAYGROUP->{"DOWNLOADS"} = [qw{
	bt/completed
	downloads
	incoming
	ed2k/Incoming
}];

my %MAPS = (
	'hotstuffs'=>'hotstuffs/all',
	'ladies'=>'todo/taskspool/ladies',
	'bt'=>'bt/completed',
	'ed2k'=>'ed2k/Incoming',
	'tv'=>'tv show',
);

sub find_babes {
	my @result;
	foreach my $dir (@DEF_DIR) {
		foreach my $cat(@{$PLAYGROUP->{"NAMES"}}) {
				next if(-l "$dir/$cat");
			foreach my $name(@_) {
				my $fd = join("/",$dir,$cat,$name);
				next if(-l $fd);
				push @result,$fd if(-d $fd);
#				print STDERR $fd,"\n";
#				return ($fd) if(-d $fd);
			}
		}
	}
	return @result;
}

sub find_videos {
	my @result;
	foreach my $dir (@DEF_DIR) {
		foreach my $name(@_) {
			if(-d $name) {
				push @result,$name;
				last;
			}
			foreach($name,ucfirst($name)) {
				my $fd = join("/",$dir,$name);
					next if(-l $fd);
				if(-d $fd) {
					push @result,$fd;
					last;
				}
			}
		}
	}
	return @result;
}

use File::Glob qw/bsd_glob/;
use Cwd qw/getcwd/;

my $IMG_EXP = qr/\.(?:jpg|png|gif|jpeg)$/;
my $VIDEO_EXP = qr/\.(?:flv|mp4|mpg|qt|ts|mpeg|avi|wmv|3gp|rm|rmvb|f4v|mp3|wma|wav)$/;
sub get_dir {
	my $dir = shift;
	my @images;
	my @videos;
	foreach(bsd_glob($dir ? "$dir/*" : '*')) {
		next if(m/^\./);
		next if(m/\/\./);
		if(-d $_) {
			my($img,$vid) = get_dir($_);
			if($img and ref $img) {
				push @images,@$img;
			}
			if($vid and ref $vid) {
				push @videos,@$vid;
			}
		}
		elsif(m/$IMG_EXP/) {
			push @images,$_;
		}
		elsif(m/$VIDEO_EXP/) {
			push @videos,$_;
		}
	}
	return (@images ? \@images : undef),(@videos ? \@videos : undef);
}

sub build_playlist {
	my $playlist = shift;
	my $prefix = shift;
	my $items = shift;
	print STDERR "Building playlist: $playlist\n";
	if(!$items) {
		print STDERR "  Nothing to do\n";
		return;
	}
	elsif(!@$items) {
		print STDERR "  Nothing to build\n";
		return;
	}
	my $fh;
	open $fh,">",$playlist;
	my $count=0;
	foreach(@$items) {
		if($OS eq 'linux') {
			$_ = "$prefix/$_" if($prefix);
		}
		else {
			$_ =~ s/\//\\/g;
			$_ = "$prefix\\$_" if($prefix);
		}
		$count++;
		print $fh $_,"\n";
	}
	close $fh;
	print STDERR " <$count items\n";
	return $playlist;
}


sub open_player {
	my $playlist = shift;
	my $player = shift(@_) || 'irfanview';
	
	if($player eq 'feh') {
		return system('feh','-f',$playlist);
	}
	elsif($player eq 'mplayer') {
		return system('mplayer','-playlist',$playlist);
	}
	elsif($player eq 'irfanview') {
		my $wpath = `cygpath -w "$playlist"`;
		chomp $wpath;
		return system('irfanview.bat','/filelist=' . $wpath)==0;
	}
	elsif($player eq 'kmplayer.bat') {
		my $wpath = `cygpath -w "$playlist"`;
		chomp $wpath;
		return system('kmplayer.bat',$wpath)==0;
	}
	elsif($player eq 'imagine') {
		my $wpath = `cygpath -w "$playlist"`;
		chomp $wpath;
		return system('imagine.bat',
			'/slide:' . $wpath,
			'--auto:3',
			'--loop:yes',
			'--full:no',
		) == 0;
	}
	elsif($player eq 'picshow') {
		my $wpath = `cygpath -w "$playlist"`;
		chomp($wpath);
		return system('picshow.bat',
				$wpath,
				'-showname',
				'-random',
				'interval=1',
		) == 0;
	}
	elsif($player eq 'kmplayer') {
		my $wpath = `cygpath -w "$playlist"`;
		chomp $wpath;
		return system('kmplayer',$wpath);
	}
}


sub play_images {
	my $player = $OS eq 'linux' ? 'feh' : 'picshow';
	foreach my $file(@_) {
		open_player($file,$player);
	}
}

sub play_videos {
	my @player = $OS eq 'linux' ? ('mplayer') :  ('kmplayer.bat');
	foreach my $file(@_) {
		open_player($file,@player);
	}
}

sub play_playlist {
	my %playlist = @_;
	foreach my $file(keys %playlist) {
		next unless(-f $file);
		my $type = $playlist{$file};
		if($type eq 'images') {
			play_images($file);
		}
		else {
			play_videos($file);
		}
	}
}

sub play_dir {
	my $dir = shift;
	my $options = shift(@_);
	my $wdir = shift;

	$dir =~ s/\/+$//;
	$options = {without=>{}} unless($options and ref $options);

	my $playname = $dir;
	if($OPTS{input}) {
		$playname = $OPTS{input};
	}


	my %data;

	my %playlist;
	$playlist{$playname . "2.m3u8"} = 'images' unless($options->{without}->{images} or $options->{without}->{image});
	$playlist{$playname . ".m3u8"}  = 'videos' unless($options->{without}->{videos} or $options->{without}->{video});

	if(!%playlist) {
		print STDERR "Error: nothing to play\n";
		return 0;
	}
	if((!$OPTS{update})) {
		my $ok = 1;
		foreach(keys %playlist) {
			if(!-f $_) {
				$ok = undef;
				last;
			}
		}
		if($ok) {
			return play_playlist(%playlist);
		}
	}
	print STDERR "Reading directory: $dir\n";
	my $CWD_KEPT = getcwd;
	chdir $dir;
	my ($images,$videos) = get_dir();
	chdir $CWD_KEPT;

	if(!($images || $videos)) {
		print STDERR "  Error: Nothing found\n";
		return undef;
	}

	$data{images} = $images;
	$data{videos} = $videos;
	
	if($wdir and $OS eq 'cygwin') {
		$wdir = `cygpath -w "$dir"`;
		chomp($wdir);
	}
	
	foreach(keys %playlist) {
		build_playlist($_,$wdir,$data{$playlist{$_}});
	}
	return play_playlist(%playlist);
}
sub parse_words {
	my $CMD_EXP = shift;
	my $DEFAULT_CMD = shift;
	my $cmd = $DEFAULT_CMD;
	my %targets;
	while(@_) {
		my $word = shift;
		my $lword = lc($word);
		next if($lword eq 'and');
		next if($lword eq 'while');
		if($lword =~ m/$CMD_EXP/) {
			$cmd = $1;
			next;
		}
		else {
			push @{$targets{$cmd}},$word;
		}
	}
	return %targets;
}
my @DEFAULT_FUCK;
my @DEFAULT_PLAY;
my @DEFAULT_PLAY_GROUP;
my $cmd = 'fuck';
my $CMD_EXP = qr/^(fuck|play)$/;
my @fuck_group;
my @play_group;

my %targets = parse_words($CMD_EXP,$cmd,@ARGV);


if($OPTS{babes}) {
	push @{$targets{fuck}},$OPTS{babes};
}
elsif(@DEFAULT_FUCK) {
	push @{$targets{fuck}},@DEFAULT_FUCK;
}

if($OPTS{videos}) {
	push @{$targets{play}},$OPTS{videos};
}
elsif(defined $targets{play}) {
	push @{$targets{play}},@DEFAULT_PLAY unless(@{$targets{play}});
}

foreach my $verb(keys %targets) {
	$targets{$verb} = {parse_words(qr/^(with|without)$/,'with',@{$targets{$verb}})};
	foreach my $opt(qw/without/) {
		my %tmp;
		if($targets{$verb}->{$opt}) {
			$tmp{$_} = 1 foreach(@{$targets{$verb}->{$opt}});
		}
		$targets{$verb}->{$opt} = \%tmp;
	}
}

my %verbs;

foreach my $verb(keys %targets) {
	next unless($targets{$verb});
	next unless($targets{$verb}->{with});
	foreach my $t(@{$targets{$verb}->{with}}) {
		foreach(split(/\s*,\s*/,$t)) {
			my $group_t;
			if(m/^group:(.+)$/) {
				$group_t = $1;
			}
			elsif($verb eq 'fuck') {
			}
			elsif(m/^[A-Z0-9_\-]+$/) {
				$group_t = $_;
			}
			if($group_t) {
				if($GROUPS{$verb} and $GROUPS{$verb}->{$group_t}) {
					push @{$verbs{$verb}},@{$GROUPS{$verb}->{$group_t}};
				}
				else {
					print STDERR "Error group for $verb not found: $group_t\n";
				}
			}
			elsif($MAPS{$_}) {
				push @{$verbs{$verb}},$MAPS{$_};
			}
			else {
				push @{$verbs{$verb}},$_;
			}
		}
	}
}

#use MyPlace::Debug::Dump;
#print STDERR &debug_dump($targets{$_},$_) . "\n" foreach(keys %targets);

foreach(keys %verbs) {
	print STDERR "$_", " ",join(", ",@{$verbs{$_}}),"\n";
}

my @babes;
my @videos;

if($verbs{fuck}) {foreach(@{$verbs{'fuck'}}) {
	push @babes,find_babes($_);
}}

if($verbs{play}) {foreach(@{$verbs{play}}) {
	push @videos,find_videos($_);
}}

my %REALPATH;
foreach(@babes) {
	my $path = $_;
	if($OS eq 'cygwin') {
		$path = `cygpath -w "$_"`;
		chomp($path);
	}
	next if($REALPATH{lc($path)});
	print STDERR "Found babes to fuck: $_\n";
	$REALPATH{lc($path)} = 1;
	play_dir($_,$targets{fuck},$path);
}

foreach(@videos) {
	my $path = $_;
	if($OS eq 'cygwin') {
		$path = `cygpath -w "$_"`;
		chomp($path);
	}
	next if($REALPATH{lc($path)});
	print STDERR "Found videos to play: $_\n";
	$REALPATH{lc($path)} = 1;
#	if(!($targets{play}->{with} and $targets{play}->{with}->{images})) {
#		$targets{play}->{without}->{images} = 1;
#	}
	play_dir($_,$targets{play},$path,'without-images'=>1);
}



__END__

=pod

=head1  NAME

fuck - PERL script

=head1  SYNOPSIS

fuck [options] ... [anyone] [[and] play [somevideo]] 

	fuck Dj_kelly and play hotstuffs
	fuck DJ-CC and play tv_shows
	fuck Amanda5330 and 张馨予

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

    2015-11-22 17:17  xiaoranzzz  <xiaoranzzz@MyPlace>
        
        * file created.

=head1  AUTHOR

xiaoranzzz <xiaoranzzz@MyPlace>

=cut

#       vim:filetype=perl
