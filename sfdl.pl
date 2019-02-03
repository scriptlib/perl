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
	help|h|? 
	manual|man
	mirror|m=s
	dest|d=s
	reject-regex|RR=s
	R|reject=s
	X|exclude-directories=s
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
#	internode=>'internode',
	vorboss=>'vorboss',
	nchc=>'nchn',
	iweb=>'iweb',
	jaist=>'jaist',
	heanet=>'heanet',
	excellmedia=>'excellmedia',
	netix=>'netix',
);
my %ua = (
	'android'=>'Mozilla/5.0 (Android 9.0; Mobile; rv:61.0) Gecko/61.0 Firefox/61.0',
	'firefox'=>'Mozilla/5.0 (Windows NT 6.1; rv,2.0.1) Gecko/20100101 Firefox/4.0.1',
	'ie'=>'Mozilla/5.0 (compatible; MSIE 9.0; Windows NT 6.1; Trident/5.0;',
	'chrome'=>'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_7_0) AppleWebKit/535.11 (KHTML, like Gecko) Chrome/17.0.963.56 Safari/535.11',
	'iphone'=>'Mozilla/5.0 (iPhone; U; CPU iPhone OS 4_3_3 like Mac OS X; en-us) AppleWebKit/533.17.9 (KHTML, like Gecko) Version/5.0.2 Mobile/8J2 Safari/6533.18.5',
);
my @WGET = (
	qw{-e robots=off --progress=dot:mega --restrict-file-names=windows},
	qw{-nc -nH -x --cut-dirs=2 -np  -r},
	qw{-o /dev/stdout --regex pcre}
);
push @WGET,'-U',$ua{firefox};

my %WGET_DEF = (
	'reject-regex'=>'C=',
	#'R','index.htm,index.html',
	'X','/icons/,/icon/',
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


foreach my $pn(@projects) {
	my $dst = $OPTS{dest} ? $OPTS{dest} : 'sf_' . $pn;
	p_tee("  Project> $pn\n");
	p_tee("Directory> $dst\n");
	clean($dst);
	foreach my $mn(@ms) {
		my $url = 'http://' . $mn . '.dl.sourceforge.net/project/' . $pn . '/';
		if($OPTS{path}) {
			$url = $url . "$OPTS{path}";
		}
		p_tee("      URL> $url\n");
		download('--referer',"http://sourceforge.net/project/$pn",'-P',$dst,$url,@appends);
	}
}
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
