#!/usr/bin/perl -w
package MyPlace::Program::Ids;
use strict;
use warnings;
use Carp;
use Getopt::Long;
use MyPlace::IdBase;
use File::Spec::Functions qw/catfile/;

my @OPTIONS = qw/
		help|h
		debug|d
		database|db:s
		overwrite|o
		source:s
/;



sub new {
	my $class = shift;
	return bless {},$class;
}

sub execute {
	my $self = shift;
	my $cmd;

	if(@_) {
		$cmd = uc(shift(@_));
	}
	else {
		$cmd = 'HELP';
	}

	if($cmd eq 'HELP') {
		$self->help(@_);
	}
	elsif($cmd eq 'LIST') {
		$self->list(@_);
	}
	elsif($cmd eq 'UPDATE') {
		$self->save(1,@_);
	}
	elsif($cmd eq 'SAVE') {
		$self->save(0,@_);
	}
	elsif($cmd eq 'SAVEURL') {
		$self->saveurl(@_);
	}
	elsif($cmd eq 'QUERY') {
		$self->query(@_);
	}
	elsif($cmd eq 'ADD') {
		$self->add(0,@_);
	}
	elsif($cmd eq 'ADDITEM') {
		$self->add(1,@_);
	}
	else {
		carp "Command '$cmd' not supported";
	}
}

sub getopt {
	my $self = shift;
	local @ARGV = @_;
	my %OPTS;
	#use Data::Dumper;
	#print Data::Dumper->Dump([\@ARGV],['@ARGV']),"\n";
	GetOptions(\%OPTS,@OPTIONS);
	#print Data::Dumper->Dump([\@ARGV],['@ARGV']),"\n";

	return \%OPTS,@ARGV;
}

sub connect_db {
	my $self = shift;
	my $opt = shift;
	my $SOURCE = $opt->{source};
	if(!$SOURCE) {
		$SOURCE = ".ids";
		foreach my $dir(".ids",catfile($ENV{HOME},".ids")) {
			if(-d $dir) {
				$SOURCE = $dir;
				last;
			}
		}
	}
	my $DBLIST = 'default';
	my $DBLIST_FILE = catfile($SOURCE,"database.lst");
	if(open FI,"<:utf8",$DBLIST_FILE) {
		$DBLIST = join("",<FI>);
		$DBLIST =~ tr/\n/,/;
		close FI;
		$DBLIST ||= 'default';
	}
	else {
		carp "Error opening '$DBLIST_FILE' for reading";
	}
	my @DB = split(/\s*,\s*/,$opt->{database} || $DBLIST);
	if($opt->{overwrite}) {
		@DB = map [$_,'overwrite'],@DB;
	}
	return MyPlace::IdBase->new($SOURCE,\@DB);
}

sub query_db {
	my $self = shift;
	my $db = shift;
	my ($status,@result) = $db->query(@_);
	if(!$status) {
		print STDERR "Error: ",@result,"\n";
		return undef;
	}
	else {
		return {@result};
	}
}

sub _each_query {
	my $self = shift;
	my $action = shift;
	my $db = shift;
	my @queries = @_ ? @_ : ('');
	foreach my $query (@queries) {
		my $target = $self->query_db($db,$query);
		if($target) {
			&$action($target,$query,$db);
		}
	}
}

sub list {
	my $self = shift;
	my $OPTS;
	($OPTS,@_) = $self->getopt(@_);
	my $db = $self->connect_db($OPTS,@_);
	my $idx = 0;
	$self->_each_query(
		sub {
			my $target = shift;
			foreach my $name(keys %{$target}) {
				next unless($target->{$name});
				print STDERR "[" . uc($name),"]:\n";
				foreach my $item(@{$target->{$name}}) {
					$idx++;
					printf "\t[%03d] %-20s [%d]  %s\n",$idx,$item->[2],$item->[3],$item->[1];
				}
			}
		},
		$db,
		@_
	);
	return $idx > 0 ? 0 : 1;
}
sub saveurl {
	my $self = shift;
	my $OPTS;
	($OPTS,@_) = $self->getopt(@_);
	my $db = $self->connect_db($OPTS,@_);
	my $url = shift;
	my $idOrName = shift;
	
	if(!$OPTS->{database}) {
		carp "Error: option '--database' must be specified";
		return 1;
	}

	if(!$idOrName) {
		carp "Error: Insufficient arguments";
		print STDERR "Usage:\n\t<program> saveurl <URL> <ID or Name>\n";
		return 1;
	}
	my($id,$name) = $db->item($idOrName);
	if(!$id) {
		return 3;
	}
	use MyPlace::URLRule::OO;
	my $URLRULE = new MyPlace::URLRule::OO('action'=>'SAVE');
	$URLRULE->autoApply({
			count=>1,
			level=>0,
			url=>$url,
			title=>join("/",$name,$OPTS->{database},$id),
	});
	if($URLRULE->{DATAS_COUNT}) {
		return 0;
	}
	else {
		return 2;
	}
}

sub add {
	my $self = shift;
	my $OPTS;
	($OPTS,@_) = $self->getopt(@_);
	my $db = $self->connect_db($OPTS,@_);
	my $ADDITEM = shift;
	my @NAMES = @_;

	my $r = 0;
	my $count;
	if(!@NAMES) {
		warn "Error: Insufficient arguments";
		print STDERR "Usage:\n\t<program> ADD|ADDITEM <Arguments...>\n";
		return 1;
	}
	elsif($ADDITEM) {
		($count) = $db->additem(@NAMES);
	}
	else {
		($count) = $db->add(@NAMES);
	}
	
	if($count) {
		$db->save;
	}
	else {
		return 2;
	}
	return 0;
}
sub save {
	my $self = shift;
	my $OPTS;
	($OPTS,@_) = $self->getopt(@_);
	my $db = $self->connect_db($OPTS,@_);
	my $DOUPDATE = shift;
	if(!@_) {
		warn "Error: Insufficient arguments";
		print STDERR "Usage:\n\t<program> SAVE|UPDATE <Arguments...>\n";
		return 1;
	}
	my @request;
	my $count = 0;
	$self->_each_query(sub {
		my $target = shift;
		foreach my $name(keys %{$target}) {
			next unless($target->{$name});
			foreach my $item(@{$target->{$name}}) {
				next unless($item && @{$item});
				push @request,{
					count=>1,
					level=>$item->[3],
					url=>$item->[2],
					title=>$item->[1] . "/$name/",
				};
				$count++;
			}
		}
	},$db,@_);

	require MyPlace::URLRule::OO;
	my $idx = 0;
	my $URLRULE = new MyPlace::URLRule::OO('action'=> $DOUPDATE ? 'UPDATE' : 'SAVE');
	foreach(@request) {
		$idx++;
		$_->{progress} = "[$idx/$count]";
		$URLRULE->autoApply($_);
		$URLRULE->reset();
	}
	if($URLRULE->{DATAS_COUNT}) {
		return 0;
	}
	else {
		return 2;
	}
}

sub help {
	my $self = shift;
	print STDERR <<"USAGEEND";
$0

Usage:
	<program> <command> [OPTIONS] [Arguments ...]

Supported commands:
	add
	additem
	list
	query
	save
	saveurl
	update
	
USAGEEND
}

return 1 if caller;
my $PROGRAM = new(__PACKAGE__);
exit $PROGRAM->execute(@ARGV);







1;

