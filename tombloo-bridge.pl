#!/usr/bin/perl -w
# $Id$
package MyPlace::Script::tombloo_bridge;


use strict;
our $VERSION = 'v0.1';
use utf8;

my %OPTS;
my @OPTIONS = qw/
	help|h|? version|ver edit-me manual|man
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


use File::Spec;
#use Encode;
my %ps;
my $lastkey;
my $tmpfile = shift;
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
unlink $tmpfile;
foreach(keys %ps) {
	if($ps{$_} eq 'undefined') {
		$ps{$_} = "";
	}
}

die("Invalid file format\n") unless($ps{item});

if($ps{tags}) {
	$ps{tags} =~ s/-/ /g;
}
$ps{item} =~ s/\s*-\s*.*-.*$//;
#foreach(@ARGV) {
#	if(m/^(.+?)=>(.*)$/m) {
#		$ps{$1}=$2;
#	}
#}
#use Data::Dumper;
#open FO,"|-",'zenity','--text-info','--filename','/dev/stdin';
#print FO Data::Dumper->Dump([\%ps],['*ps']),"\n";
#close FO;

my $topdir;
if($ps{profd}) {
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

my $filename= $ps{itemUrl} || $ps{itemPageUrl};
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
$filename =~ s/[:\?\*\\\/]+/_/g;
$filename = File::Spec->catfile($alldir,$filename);

if($ps{tags}) {
	$ps{tags} =~ s/\s*,\s*/, /g;
}
if($ps{'body-file'}) {
	open FI,'<',$ps{'body-file'};
	$ps{body} = join("",<FI>);
	close FI;
}
if($ps{type} eq 'photo') {
	if($ps{file}) {
		system('cp','-v','--',$ps{file},$filename);
		unlink($ps{file});
	}
	else {
		system('download','-r',$ps{pageUrl},'--saveas',$filename,$ps{itemUrl});
	}
	system('tagfs','-r',$topdir,$ps{tags},$filename);
}

$filename = $filename . ".txt";
open FO,'>',$filename;
print FO join(
	"\n\n",(
			$ps{item} . "\n" . $ps{itemUrl},
			$ps{body},
			$ps{description} . "\n" . "[" . $ps{tags} . "]",
			"source:$ps{pageUrl}"
		  )
	),"\n";
close FO;
system('tagfs','-r',$topdir,$ps{tags},$filename);
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
