#!/usr/bin/perl -w
# $Id$
package MyPlace::Script::create_url_rss;
use strict;

our $VERSION = 'v0.1';
my @OPTIONS = qw/
	help|h|? 
	manual|man
	title|t=s
	description|desc|d=s
	generator|gen|g=s
	author|a=s
	verbose|v
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

my $url = shift;
use MyPlace::URLRule;
use MyPlace::RSS::Writer;

my ($st,$source,$page,@pages);

($st,$source) = MyPlace::URLRule::request($url,':rss');
if(!$st) {
	print STDERR $source->error,"\n";
	exit 1;
}

foreach(@{$source->{page}}) {
	($st,$page) = MyPlace::URLRule::request($_,':rsspage');
	if(!$st) {
		print STDERR $page->error,"\n";
		exit 2;
	}
	push @pages,$page;
}



my %DUP;
if(open FI,'<','GUID.db') {
	while(<FI>) {
		chomp;
		s/\t.+$//;
		$DUP{$_} = 1;
	}
	close FI;
}
open FO,">>",'GUID.db';


print rss_start(%OPTS),"\n";
my $p_c = scalar(@pages);
my $p_i = 0;
my $ignore_c = 0;
foreach my $res(@pages) {
	$p_i++;
	next unless($res->{item} and @{$res->{item}});
	my $r_c = scalar(@{$res->{item}});
	my $r_i = 0;
	foreach(@{$res->{item}}) {
		$r_i++;
		my $pos = "[$p_i/$p_c][$r_i/$r_c]";
		if($_->{guid}) {
			if($DUP{$_->{guid}}) {
				if($OPTS{verbose}) {
					print STDERR "$pos <GUID.db> ignore: ",$_->{guid},"[$_->{title}]\n";
				}
				#else {
				#	print STDERR "$pos <GUID.db> ignore: ",$_->{guid},"\n";
				#}
				$ignore_c++;
				next;
			};
			$DUP{$_->{guid}} = 1;
		}
		my $link = $_->{link};
		if($link) {
			print STDERR $pos," ";
			my ($status,$item) = MyPlace::URLRule::request($link,':rssitem');
			if($status) {
				$_->{description} = $item->{description}; 
			}
			sleep 1;
			print STDERR "  OK: " . length($_->{description} || "") . ", " . $_->{title}  . "\n";
			print FO $_->{guid},"\t",$_->{title},"\n";
		}
		else {
			print STDERR "  No link found!\n";
		}
		print rss_item($_),"\n";
	}
}
print STDERR "----\n$ignore_c items ignored\n" if($ignore_c>1);
print rss_end(%OPTS),"\n";
close FO;



__END__

=pod

=head1  NAME

create_url_rss - PERL script

=head1  SYNOPSIS

create_url_rss [options] ...

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

    2015-11-24 01:57  xiaoranzzz  <xiaoranzzz@MyPlace>
        
        * file created.

=head1  AUTHOR

xiaoranzzz <xiaoranzzz@MyPlace>

=cut

#       vim:filetype=perl
