#!/usr/bin/perl -w
# $Id$
package MyPlace::Script::search_torrents;
use strict;
use MyPlace::Script::Message;

our $VERSION = 'v0.1';
my @OPTIONS = qw/
	help|h|? 
	manual|man
	download|d
	engine|e:s
	dest:s
/;
my %OPTS;
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


my %ENGINES = (
	'torrentproject'=>[
		'http://torrentproject.se/?safe=off&t=###QUERY###',
		2,
	],
	'bitsnoop'=>[
		'http://bitsnoop.com/search/all/###QUERY###+safe:no/c/d/1',
		2,
	],
	'torrentkitty.org'=>[
		'http://www.torrentkitty.org/search/###QUERY###/',
		1,
	],
	'sobt.org'=>[
		'http://www.sobt.org/Query/###QUERY###',
		1,
	],
);



my %engine;
my @DATA;

if($OPTS{engine}) {
	foreach(keys %ENGINES) {
		if(m/$OPTS{engine}/) {
			$engine{$_} = $ENGINES{$_};
		}
	}
}
else {
	%engine = %ENGINES;
}

if(!%engine) {
	app_error "No search engine specified\n";
	exit 1;
}


if(!@ARGV) {
	foreach my $fk(qw/keywords.lst keywords.txt search.ini/) {
		next unless(-f $fk);
		app_message2 "Read queires from <$fk>\n";
		open FI,'<',$fk or next;
		foreach(<FI>) {
			s/[\r\n]+$//;
			next unless($_);
			push @ARGV,$_;
			app_message2 "  : $_\n" 
		}
		close FI;
	}
}

if(!@ARGV) {
	app_warning "Usage:$0 [-d] <Queries...>\n";
	exit 1;
}

if($OPTS{dest}) {
	if(! -d $OPTS{dest}) {
		mkdir $OPTS{dest} or die("Error creating directory $OPTS{dest}: $!\n");
	}
	chdir $OPTS{dest} or die("Error changing to directory $OPTS{dest}: $!\n");
	app_warning "Enter $OPTS{dest} ...\n";
}
foreach my $QUERY(@ARGV) {
	foreach(keys %engine) {
		app_message2 "Search \<$QUERY\> using engine \[$_\]\n";
		my $url = $engine{$_}[0];
		my $level = $engine{$_}[1];
		$url =~ s/###QUERY###/$QUERY/g;
		my @prog = ('urlrule_action',$url,$level);
		push @prog,"SAVE" if($OPTS{download});
		system(@prog);
	}
}

__END__

=pod

=head1  NAME

search_torrents - PERL script

=head1  SYNOPSIS

search_torrents [options] ...

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

    2014-10-15 03:14  xiaoranzzz  <xiaoranzzz@MyPlace>
        
        * file created.

=head1  AUTHOR

xiaoranzzz <xiaoranzzz@MyPlace>

=cut

#       vim:filetype=perl
