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
my $msg = MyPlace::Script::Message->new("Saveurl");
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
);

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
	$filename = normalize($filename);
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
	system('mv','-v','--',$link,$filename);
}
sub process_qvod {
	my ($link,$filename) = @_;
	if(!$filename) {
		if($link =~ m/([^\|]+)\|$/) {
			$filename = $1;
		}
		elsif($link =~ m/\/([^\/]+)$/) {
			$filename = $1;
		}
	}
	$filename = normalize($filename);
	if(-f $filename) {
		$msg->warning("Ignored: File exists, $filename\n");
		return;
	}
	if($link && $filename) {
		$msg->green("Saving file $filename.qsed\n");
		open FO,'>',$filename . '.qsed';
		print FO 
<<"EOF";
	<qsed version="3.5.0.61">
		<entry>
			<ref href="$link"/>
		</entry>
	</qsed>
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
	elsif(m/^(http:\/\/.+)\t(.+)$/) {
		process_http($1,$2);
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
