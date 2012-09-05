#!/usr/bin/perl -w
# $Id$
package MyPlace::Script::bookmarks_json2html;
use strict;

our $VERSION = 'v0.1';
my @OPTIONS = qw/
	help|h|? 
	manual|man
	source|s:s
	json|j:s
	html:s
	target:s
	output:s
	perl|p:s
	text|txt|t:s
	private
	exclude|x:s
	include|i:s
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



use JSON;
use Data::Dumper;
use MyPlace::Bookmarks::HTML;
our @bookmarks;
our $bookmarks;
my %urls;
my @folders;
my $type = 'json';
my @source;
binmode STDERR,'utf8';
binmode STDOUT,'utf8';

$OPTS{'source'} = shift unless($OPTS{'source'});
if($OPTS{'json'}) {
	@source = split(/\s*,\s*/,$OPTS{'json'});
}
elsif($OPTS{'source'}) {
	@source = split(/\s*,\s*/,$OPTS{'source'});
	if($OPTS{'source'} =~ m/\.p[lm]/) {
		$type = 'perl';
	}
	else {
		$type = 'json';
	}
}
else {
	require Pod::Usage;
	Pod::Usage::pod2usage(-exitval=>1,-verbose=>1);
	exit 1;	
}

if($type eq 'json') {
	foreach(@source) {
		print STDERR "Reading source JSON file";
		my @data;
		open FI,'<',$_ or die;
		@data = <FI>;
		close FI;
		print STDERR "\t[OK]\n";

		print STDERR "Converting JSON object to PERL";
		$bookmarks = decode_json(join("",@data));
		print STDERR "\t[OK]\n";

		if($OPTS{perl}) {
			print STDERR "Writting PERL object to file $OPTS{perl}";
			open FO,'>:utf8',$OPTS{perl} or die;
			print FO Data::Dumper->Dump([$bookmarks],['bookmarks']);
			close FO;
			print STDERR "\t[OK]\n";
		}

		push @bookmarks,$bookmarks;
	}
}
else {
	foreach(@source) {
		print STDERR "Reading source PERL file $_";
		do $_;
		push @bookmarks,$bookmarks;
		print STDERR "\t[OK]\n";
	}
}


sub from_entry {
	my $entry = shift;
	if($entry->{annos}) {
		foreach(@{$entry->{annos}}) {
			if($_->{'name'} eq 'bookmarkProperties/description') {
				$entry->{desc} = $_->{'value'};
				last;
			}
		}
	}
	$entry->{private} = 1 if($OPTS{private});
	$entry->{tags} = [] unless($entry->{tags});
	$entry->{title} = '' unless($entry->{title});
	$entry->{desc} = '' unless($entry->{desc});
	return $entry;
}


my $count = 0;
sub process {
	my $entry = shift;
	my $tag = shift;
	next unless($entry->{type});
	if($entry->{type} eq 'text/x-moz-place') {
		return unless($entry->{uri});
		if($urls{$entry->{uri}}) {
#			$urls{$entry->{uri}} = {%{$entry},%{$urls{$entry->{uri}}}};
		}
		else {
			$urls{$entry->{uri}} = from_entry($entry);
		}
		my $this = $urls{$entry->{uri}};
		if($tag) {
			if($this->{tags}) {
				push @{$this->{tags}},$tag if($tag);
			}
			else {
				$this->{tags} = [$tag];
			}
		}
		print STDERR "\b"x20,"\r[",$count++,"] bookmarks processed.";#,$entry->{uri},"\n";
	}
	elsif($entry->{type} eq 'text/x-moz-place-container') {
		my @nodes = @{$entry->{children}};
		my $tag = $entry->{title};
#		print STDERR "\n$tag:\n";
		foreach(@nodes) {
			process($_,$tag);
		}
	}
}

print STDERR "Processing bookmark entries...\n\n";
foreach(@bookmarks) {
	process($_);
}
print STDERR "\n";

if($OPTS{txt}) {
	print STDERR "Writting bookmarks text file";
	open FO,'>:utf8',$OPTS{txt} or die("\t[FAILED]\n$!\n");
	foreach(keys %urls) {
		my $bookmark = $urls{$_};
		print FO $_,' [',join(", ",@{$bookmark->{tags}}),']',"\n\t",$bookmark->{title},"\n\t$bookmark->{desc}\n";
	}
	close FO;
	print STDERR "\t[OK]\n";
}

my $target = $OPTS{'target'} || $OPTS{'output'} || $OPTS{'html'};# || 'bookmarks.html';
if($target) {
	print STDERR "Writting HTML bookmarks to \"$target\"";
	open FO,'>:utf8',$target or die("$!\n");
}
else {
	print STDERR "Printing HTML bookmarks...\n";
	open FO,'>&STDOUT' or die("$!\n");
}

print FO MyPlace::Bookmarks::HTML::header;
$count = 0;
foreach(keys %urls) {
	my $bm = $urls{$_};
	next if($OPTS{exclude} and $_ =~ m/$OPTS{exclude}/i);
	next if($OPTS{include} and $_ !~ m/$OPTS{include}/i);
	$count++;
	print FO MyPlace::Bookmarks::HTML::bookmark($bm);
}
print FO MyPlace::Bookmarks::HTML::footer;
close FO;

print STDERR "\t[OK]\nOutput $count bookmarks.\n";

__END__

=pod

=head1  NAME

bookmarks-json2html - PERL script

=head1  SYNOPSIS

bookmarks-json2html [options] ...

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

=item B<--source>,B<-s>

Specified source files, json or perl format.

=item B<--target>,B<--output>,B<--html>,B<-o>

Specified output filename.

=item B<--perl>,B<-p>

Convert json to perl format.

=item B<--json>,B<-j>

Specified json format source files.

=item B<--text>,B<-t>

Output bookmarks data to text file.

=item B<--private>

Keep each bookmark private.

=item B<--include>

Specified REGEX pattern for selecting bookmarks.

=item B<--exclude>

Specified REGEX pattern for ignoring bookmarks.

=back

=head1  DESCRIPTION

___DESC___

=head1  CHANGELOG

    2012-06-17 23:15  xiaoranzzz  <xiaoranzzz@myplace.hell>
        
        * file created.
		* version 0.1.

=head1  AUTHOR

xiaoranzzz <xiaoranzzz@myplace.hell>

=cut

#       vim:filetype=perl
