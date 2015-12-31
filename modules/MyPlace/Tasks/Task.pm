#!/usr/bin/perl -w
package MyPlace::Tasks::Task;
BEGIN {
    require Exporter;
    our ($VERSION,@ISA,@EXPORT,@EXPORT_OK,%EXPORT_TAGS);
    $VERSION        = 1.00;
    @ISA            = qw(Exporter);
    @EXPORT         = qw();
    @EXPORT_OK      = qw($TASK_STATUS);
}
use strict;
use warnings;

our $STATUS = {
	'PENDING'=>0,
	'WORKING'=>1,
	'FINISHED'=>2,
	'ERROR'=>3,
	'IGNORED'=>4,
	'DONOTHING'=>20,
	'FATALERROR'=>30,
	'NEWTASKS'=>40,
};

our $TASK_STATUS = $STATUS;

sub status {
	my $self = shift;
	foreach(keys %$STATUS) {
		if($self->{status} == $STATUS->{$_}) {
			return $_;
		}
	}
	return 'UNKNOWN';
}

sub new {
	my $class = CORE::shift;
	my $namespace = shift(@_) || "myplace-tasks";
	my $self = bless {status=>$STATUS->{PENDING},namespace=>$namespace},$class;
	$self->{definition} = [];
	if(@_) {
		$self->{definition} = [@_];
	}
	return $self;
}

sub content {
	my $self = shift;
	return @{$self->{definition}};
}

sub new_from_string {
	my $class = shift;
	my $self = new($class);
	return $self->load(@_);
}

sub namespace {
	my $self = CORE::shift;
	return $self->{namespace};
}

sub redefine {
	my $self = shift;
	$self->{definition} = [@_];
	return $self;
}

sub to_string {
	my $self = CORE::shift;
	return $self->{title} if($self->{title});
	my $sep = shift(@_) || ' ';
	return "\[$self->{namespace}\] " .  join($sep,@{$self->{definition}});
}


sub save {
	my $self = CORE::shift;
	return join("\t",$self->{namespace},@{$self->{definition}});
}

sub load {
	my $self = CORE::shift;
	my $text = CORE::shift(@_) || 'myplace-tasks';
	($self->{namespace},@{$self->{definition}}) = split(/\s*(?:[\>\t]|\\t)\s*/,$text);
	return $self;
}

sub queue {
	my $self = CORE::shift;
	return unless(@_);
	if(!$self->{NEWTASKS}) {
		$self->{NEWTASKS} = [];
	}
	push @{$self->{NEWTASKS}},[@_];
	return $self->{NEWTASKS};
}

sub tasks {
	my $self = shift;
	return @{$self->{NEWTASKS}} if($self->{NEWTASKS});
}

1;

