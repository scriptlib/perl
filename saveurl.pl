#!/usr/bin/perl -w
# $Id$
package MyPlace::Script::saveqvod;
use strict;

our $VERSION = 'v0.2';
my @OPTIONS = qw/
	help|h|? 
	manual|man
/;
my %OPTS;
use MyPlace::Script::Message;
use MyPlace::Program::Download;
my $downloader = new MyPlace::Program::Download;
my $msg = MyPlace::Script::Message->new();
if(@ARGV)
{
    require Getopt::Long;
    Getopt::Long::GetOptions(\%OPTS,@OPTIONS);
}
if($OPTS{'help'} or $OPTS{'manual'}) {
	require Pod::Usage;
	my $v = $OPTS{'help'} ? 1 : 2;
	Pod::Usage::pod2usage(-exitval=>$v,-verbose=>$v);
    exit $v;
}

my @BLOCKED = (
	'rapidimg\.org',
	'7seasex\.com',
	'sadpanda\.us',
	'imagehost\.it',
	'freespace\.com\.au',
	'imgjoe\.com',
	'leetleech\.org',
	'imgkeep\.com',
	'uyl\.me',
	'789zy\.us',
	'item\.slide\.com',
	'umei\.cc',
	'flare\.me',
	'fototube\.pl',
	'shareimage\.org',
	'imagevenue\.com',
	'imgchili\.com',
	'imagekiss\.com',
	'tinypic\.com',
	'ojiji\.net',
	'mmsky\.net',
	'snapfish\.com',
	'15335\.com',
	'gg88\.com',
	'slide\.com',
	'donsnaughtymodels\.com',
	'dosug\.cz',
	'imagehyper\.com',
	'totallynsfw\.com',
	'img\.vkdt\.info',
	'mmyishu\.com:99',
	'schoolgirl-bdsm\.jp',
	'imgly\.net',
	'imgplanet\.com',
);

my %EXPS = (
	"bdhd"=>'^(bdhd:\/\/.*\|)([^\|]+?)(\|?)$',
	'ed2k'=>'^(ed2k:\/\/\|file\|)([^\|]+)(\|.*)$',
	'http'=>'^(http:\/\/.*\/)([^\/]+)$',
	'qvod'=>'^(qvod:\/\/.*\|)([^\|]+?)(\|?)$',
);

sub extname {
	my $filename = shift;
	return "" unless($filename);
	if($filename =~ m/\.([^\.\/\|]+)$/) {
		return $1;
	}
	return "";
}
sub blocked {
	my $url = shift;
	foreach(@BLOCKED) {
		if($url =~ m/$_/) {
			return 1;
		}
	}
	return undef;
}

sub normalize {
	my $_ = $_[0];
	if($_) {
		s/[\/:\\]/ /g;
	}
	return $_;
}
sub process_http {
	my ($link,$filename) = @_;
	if(blocked($link)) {
		$msg->warning("Blocked: $link\n");
		return;
	}
	if(!$filename) {
		if($link =~ m/$EXPS{http}/) {
			$filename = $2;
		}
	}
	$filename = normalize($filename) if($filename);
	if(-f $filename) {
		$msg->warning("Ignored: File exists, $filename\n");
		return;
	}
	$msg->green("Saving file $filename\n");
	return $downloader->execute('-u',$link,'-s',$filename,'-m','60');
#	system('download','-u',$link,'-s',$filename);
	
}
sub process_file {
	my ($link,$filename) = @_;
	$filename = normalize($filename);
#	if(-f $filename) {
#		print STDERR "Ignored: File exists, $filename\n";
#		return;
#	}
	$msg->green("Saving file $filename\n");
	system('mv','--',$link,$filename);
}


sub process_bdhd {
	my $link = shift;
	my $filename = shift;
	$link = lc($link);
	if(!$filename) {
		foreach($EXPS{bdhd},$EXPS{ed2k},$EXPS{qvod},$EXPS{http}) {
			if($link =~ m/$_/) {
				$filename = $2;
				$filename = normalize($filename);
				last;
			}
		}
	}
	else {
		$filename = normalize($filename);
		foreach($EXPS{bdhd},$EXPS{ed2k},$EXPS{qvod}) {
			if($link =~ m/$_/) {
				$link = $1 . $filename . $3;
				last;
			}
		}
	}
	if($link && $filename) {
		$filename = $filename . ".bsed";
		$msg->green("Saving file $filename\n");
		open FO,'>',$filename;
		print FO 
<<"EOF";
{
	"bsed":{
		"version":"1,19,0,195",
		"seeds_href":{"bdhd":"$link"}
	}
}
EOF
		close FO;
	}
	else {
		print STDERR "No filename specified for [$link]\n";
	}
}

sub process_qvod {
	my $link = shift;
	my $filename = shift;
	$link = lc($link);
	if(!$filename) {
		foreach($EXPS{qvod},$EXPS{bdhd},$EXPS{ed2k},$EXPS{http}) {
			if($link =~ m/$_/) {
				$filename = $2;
				last;
			}
		}
		$filename = normalize($filename) if($filename);
	}
	else {
		$filename = normalize($filename);
		foreach($EXPS{qvod},$EXPS{bdhd},$EXPS{ed2k}) {
			if($link =~ m/$_/) {
				$link = $1 . $filename . $3;
				last;
			}
		}
	}
	if($link && $filename) {
		$msg->green("Saving file $filename.qsed\n");
		open FO,'>',$filename . '.qsed';
		print FO 
<<"EOF";
<qsed version="3.5.0.61"><entry>
<ref href="$link" />
</entry></qsed>
EOF
		close FO;
	}
}
while(<STDIN>) {
	chomp;
	if(m/^qvod:(.+)\t(.+)$/) {
		process_qvod($1,$2);
	}
	elsif(m/^qvod:(.+)$/) {
		process_qvod($1);
	}
	elsif(m/^bdhd:(.+)\t(.+)$/) {
		process_bdhd($1,$2);
	}
	elsif(m/^bdhd:(.+)$/) {
		process_bdhd($1);
	}
	elsif(m/^(ed2k:\/\/.+)\t(.+)$/) {
		process_bhdh($1,$2);
	}
	elsif(m/^(ed2k:\/\/.+)$/) {
		process_bhdh($1);
	}
	elsif(m/^(http:\/\/.+)\t(.+)$/) {
		process_http($1,$2);
	}
	elsif(m/^(http:\/\/.+)$/) {
		process_http($1);
	}
	elsif(m/^file:\/\/(.+)\t(.+)$/) {
		process_file($1,$2);
	}
	elsif(m/^file:\/\/(.+)$/) {
		process_file($1,"./");
	}
	else {
		$msg->warning("Ignored: URL not supported, $_\n");
	}
}


__END__

=pod

=head1  NAME

saveqvod - PERL script

=head1  SYNOPSIS

saveqvod [options] ...

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

    2013-10-07 08:24  xiaoranzzz  <xiaoranzzz@Mainstream>
        
        * file created.

=head1  AUTHOR

xiaoranzzz <xiaoranzzz@Mainstream>

=cut

#       vim:filetype=perl
