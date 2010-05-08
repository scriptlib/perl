#!/usr/bin/perl -w
package NightGun::Store::Archive;
use strict;
use warnings;
use NightGun::Store::Base;
#use encoding "utf8";

my $PACKAGE_NAME="NightGun::Store::Archive";
my $PATH_SEP='::';
my $PATH_EXP="^(.*)$PATH_SEP\/(.*)\$";
$PATH_EXP = qr/$PATH_EXP/;
my %CACHED;
my %CACHED_BOOK;
use MyPlace::Archive;

sub new {
	my ($class,$solid_type) = @_;
        my $self = bless {%{NightGun::Store::Base->new()},name=>"Archive"},$class;
        if($solid_type) {
            my $handler = MyPlace::Archive->new($solid_type);
            if($handler) {
                $self->{handler}=$handler;
            }
        }
	return $self;
}

sub parse_location {
    my $self = shift;
    my $path = shift;
   # $path =~ s/^jar:file://g;
    $path =~ s/%\/+/\//;
    $path =~ s/!\//$PATH_SEP\//;
    if($path =~ $PATH_EXP) {
        return $1,$path;
    }
    else {
        return $path,"";
    }
}

sub load {
    my ($self,$path) = @_;
    my $source = $path;
    my $entry = "";
    if($path =~ $PATH_EXP ) {
        $source = $1;
        $entry = $2;
    }
    return undef unless(-f $source);
    return undef if($CACHED_BOOK{$source} and $CACHED_BOOK{$source} eq "no");
    my $archive = $self->{handler} ? $self->{handler} : MyPlace::Archive->new($source);
    $CACHED_BOOK{$source} = "no" unless($archive);
    return undef unless($archive);
    $self->{save_history}=1;
    $self->{filetype}=$archive;
    $self->{single}=0;
LoadEntry:
    if($entry and $entry !~ /\/$/) {
        $self->{single}=1;
        $self->{name}=$path;
        $self->{parent}=$path;
        $self->{parent} =~ s/\/[^\/]+$/\//;
        $self->{text}=$archive->extract($source,$entry);
    }
    else { 
        my ($dirs,$files) = $self->list_archive($archive,$source,$entry);
        if(@{$CACHED{$source}->{dirs}} == 0 and @{$CACHED{$source}->{files}} == 1) {
            $self->{single}=1;
            $self->{text} = $archive->extract($source,$CACHED{$source}->{files}->[0]);
        }
        else {
            $self->{files} = $files;
            $self->{directories} = $dirs;
            if($entry) {
                $self->{name} = $source . $PATH_SEP . "\/" . $entry;
                $self->{parent} = $self->{name};
                $self->{parent} =~ s/[^\/]+\/$//;
            }
            else {
                $self->{name} = $source;
                $self->{parent} = $source;
                $self->{parent} =~ s/\/[^\/]*$/\//;
            }
        }
    }
    if($self->{parent} and ($self->{parent} eq $source . "$PATH_SEP/") ) {
        my $l = length($self->{parent}) - length("$PATH_SEP/");
        $self->{parent} = substr($self->{parent},0,$l);
    }
    $self->{location} = [$source,$entry ? $path : ""];
    $self->{title} = $path;
    $self->{path} = $path;
    return $self;
}


sub list_archive {
    my ($self,$handler,$source,$entry,@cmds) = @_;

    my ($fh,@dirs,@files);
    $entry = "" unless($entry);
    if($entry) {
        $entry .= "/" unless($entry =~ /\/$/);
    }
    my (@c_dirs,@c_files);
    unless($CACHED{$source}) {
        ($CACHED{$source}{dirs},$CACHED{$source}{files}) = 
            $handler->list($source);
    }
    @c_dirs = @{$CACHED{$source}{dirs}};
    @c_files = @{$CACHED{$source}{files}};

    my $filter = $entry ? qr/^$entry[^\/]+\/?$/ : qr/^[^\/\\]+\/?$/;
    @dirs = map {$source . $PATH_SEP . "\/" . $_} ( grep (/$filter/,@c_dirs));
    @files = map {$source . $PATH_SEP . "\/" . $_} ( grep (/$filter/,@c_files));
    return @dirs ? \@dirs : [],@files? \@files : [];
}

1;
