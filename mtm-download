#!/usr/bin/perl -w
# $Id$
package MyPlace::Script::mtm_download;
use strict;

our $VERSION = 'v0.1';
my @OPTIONS = qw/
	help|h|? 
	manual|man
	overwrite|o
	force|f
	input|i=s
	directory|d=s
	title|t=s
	retry
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

use MyPlace::Tasks::Manager;
my $mtm = MyPlace::Tasks::Manager->new(
	directory=>$OPTS{directory},
	worker=>sub {
		my $line = shift;
		my @opts = @_;
		my $url;
		my $filename;
		if($line =~ m/^\s*([^\t]+)\t(.+?)\s*$/) {
			$url = $1;
			$filename = $2;
		}
		else {
			$url = $line;
		}
		if($url =~ m/weipai\.cn|oldvideo\.qiniudn\.com/) {
			return system('download_weipai_video',$url,$filename);
		}
		else {
			push @opts,'--url',$url;
			push @opts,'--saveas',$filename;
			return system('download',@opts);
		}
	},
	title=>$OPTS{title} || $OPTS{directory},
	force=>$OPTS{force},
	overwrite=>$OPTS{overwrite},
	retry=>$OPTS{retry},
);

if($OPTS{input}) {
	$mtm->set('input',$OPTS{input});
}
if($mtm->run(@ARGV)) {
	exit 0;
}
else {
	exit 1;
}


__END__

=pod

=head1  NAME

mtm-download - PERL script

=head1  SYNOPSIS

mtm-download [options] inputs...

	mtm-download --force 'http://aliv.weipai.cn/201408/14/16/007F1EF5-0AE5-41B9-950B-97655752B0DA.jpg  2014081416_隔离霜微信卖家：zj605227619 面膜和唇彩微信卖家：rococoshop.jpg'
	cat urls.txt | mtm-download --overwrite
	mtm-download --force --overwrite --input urls.lst

=head1  OPTIONS

=over 12

=item B<-i>,B<--input>

Read URLs definition from specified fil

=item B<-f>,B<--force>

Force download mode, ignored URLs database

=item B<-o>,B<--overwrite>

Overwrite download mode

=item B<-t>,B<--title>

Specified prompting text

=item B<-d>,B<--directory>

Specified working directory

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

Downloader use MyPlace::Tasks::Manager

=head1  CHANGELOG

    2015-01-26 02:34  xiaoranzzz  <xiaoranzzz@MyPlace>

		* version 0.1

    2015-01-26 02:19  xiaoranzzz  <xiaoranzzz@MyPlace>
        
        * file created.

=head1  AUTHOR

xiaoranzzz <xiaoranzzz@MyPlace>

=cut

#       vim:filetype=perl
