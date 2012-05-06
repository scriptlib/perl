#!/usr/bin/perl -w
# $Id$
package MyPlace::Script::tombloo_bridge;


use strict;
our $VERSION = 'v0.1';
use utf8;

my %OPTS;
my @OPTIONS = qw/
	help|h|? version|ver edit-me manual|man
	topdir:s
	profd:s
	item:s
	itemUrl:s
	pageUrl:s
	tags:s
	description:s
	body:s
	body-file:s
	type:s
	test|t
	/;

#use Data::Dumper;
#open FO,"|-",'zenity','--text-info','--filename','/dev/stdin';
#print FO Data::Dumper->Dump([\@ARGV],['*ARGV']),"\n";
#close FO;

if(@ARGV)
{
    require Getopt::Long;
    Getopt::Long::GetOptions(\%OPTS,@OPTIONS);
}
else {
	$OPTS{'help'} = 1;
}

if($OPTS{'help'} or $OPTS{'manual'}) {
	my $v = $OPTS{'help'} ? 1 : 2;
	require Pod::Usage;
	Pod::Usage::pod2usage(-exitval=>$v,-verbose=>$v);
	exit($v);
}

sub parse_file {
	my %ps;
	my $tmpfile = shift;
	my $lastkey;
	open FI,'<',$tmpfile or die("$!\n");
	while(<FI>) {
		if(m/^(.+?)=>(.*)$/m) {
			$lastkey = $1;
			$ps{$lastkey} = $ps{$lastkey} ? $ps{$lastkey} . "\n" . $2 : $2;
		}
		elsif($lastkey) {
			$ps{$lastkey} .= "\n" . $_;
		}
	}
	close FI;
	return %ps;
}

use File::Spec;
#use Encode;
use vars qw/%ps $PAGE $topdir/;
if(@ARGV) {
	my $tmpfile = shift;
	if(-f $tmpfile) {
		%ps = parse_file($tmpfile);
		unlink $tmpfile;
	}
	else {
		unshift @ARGV,$tmpfile;
	}
}
%ps = (%ps, %OPTS);
foreach(@ARGV) {
	if(m/^(.+?)=>(.+)$/m) {
		$ps{$1} = $2;
	}
}

foreach(keys %ps) {
	if($ps{$_} eq 'undefined') {
		$ps{$_} = "";
	}
}

foreach(qw/
	itemUrl
	item
	body
	body-file
	description
	pageUrl
	type
	profd
	topdir
	tags
	/) {
	$ps{$_} = "" unless($ps{$_});
}

#use Data::Dumper;
#open FO,"|-",'zenity','--text-info','--filename','/dev/stdin';
#print FO Data::Dumper->Dump([\%ps],['*ps']),"\n";
#close FO;

die("Invalid file format\n") unless($ps{item});

if($ps{tags}) {
	$ps{tags} =~ s/-/ /g;
}
$ps{item} =~ s/\s*-\s*.*-.*$//;
$ps{body} = "" unless($ps{body});
#foreach(@ARGV) {
#	if(m/^(.+?)=>(.*)$/m) {
#		$ps{$1}=$2;
#	}
#}

if($ps{topdir}) {
	$topdir = $ps{topdir};
}
elsif($ps{profd}) {
	$topdir =  File::Spec->catfile($ps{profd},'websaver');
}
else {
	$topdir =  File::Spec->catfile($ENV{'HOME'},'.websaver');
};
if(! -d $topdir) {
	mkdir($topdir) or die("$!\n");
}
my $alldir = File::Spec->catfile($topdir,'all');
if(! -d $alldir) {
	mkdir($alldir) or die("$!\n");
}

my $filename= $ps{itemUrl} || $ps{pageUrl};
if($ps{type} eq 'photo') {
	if($filename) {
		$filename =~ s/\/+$//;
		$filename =~ s/.*\/+//;
		$filename = $ps{item} . '_' . $filename;
	}
}
else {
	$filename = $ps{item};
}
$filename =~ s/[:><\?\*\\\/=\|!@#%^&{}]+/_/g;
$filename =~ s/\s*_+\s*/_/g;
$filename =~ s/\s+$//;
$filename =~ s/^\s+//;
$filename = File::Spec->catfile($alldir,$filename);

if($ps{tags}) {
	$ps{tags} =~ s/\s*,\s*/, /g;
}
if($ps{'body-file'}) {
	open FI,'<',$ps{'body-file'};
	$ps{body} = join("",<FI>);
	close FI;
}

my $now = time;
if($ps{itemUrl}) {
	my $bmfile = File::Spec->catfile($topdir,'bookmarks.html');
	print STDERR "Writting to $bmfile...";
	if(!$OPTS{test}) {
		open FO,'>>',$bmfile or die("$!\n");
		print FO <<"HTML";
<DT><A HREF="$ps{itemUrl}" TYPE="$ps{type}" SOURCE="$ps{pageUrl}" TAGS="$ps{tags}" ADD_DATE="$now">$ps{item}</A>
<DD>$ps{body}$ps{description}
HTML
		close FO;
	}
	print STDERR "\t[OK]\n";
}

if($OPTS{test}) {
	use Data::Dumper;print STDERR Data::Dumper->Dump([\%ps],['*ps']),"\n";
}
elsif($ps{type} eq 'photo') {
	if($filename !~ m/\.[^\.]{3,4}$/) {
		$filename = $filename . ".jpg";
	}
	if($ps{file}) {
		system('cp','-v','--',$ps{file},$filename);
		unlink($ps{file});
	}
	else {
		system('download','-r',$ps{pageUrl},'--saveas',$filename,$ps{itemUrl});
	}
	if(-f $filename) {
		system('tagfs','-r',$topdir,$ps{tags},$filename);
	}
}
elsif($ps{type} =~ /^(:?regular|text|quote)$/) {
	$filename = $filename . ".txt";
	my $under = '=' x length($ps{item});
	open FO,'>',$filename;
	print FO <<"ARTICLE";
$ps{item}
$under

* [$ps{tags}]
* Source: <$ps{itemUrl}>
* Link: <$ps{pageUrl}>

$ps{body}$ps{description}
ARTICLE
	close FO;
	system('tagfs','-r',$topdir,$ps{tags},$filename);
}

my $hook = File::Spec->catfile($topdir,'tb-hook.pl');
if(-f $hook) {
	eval `cat $hook` or die("$@\n");
}

#system('zenity','--info','--text',$filename . "\n" . $ps{tags});

__END__

=pod

=head1  NAME

tombloo-bridge - PERL script

=head1  SYNOPSIS

tombloo-bridge [options] ...

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

    2011-12-29 20:58  xiaoranzzz  <xiaoranzzz@myplace.hell>
        
        * file created.

=head1  AUTHOR

xiaoranzzz <xiaoranzzz@myplace.hell>

=cut

#       vim:filetype=perl
