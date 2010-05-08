#!/usr/bin/perl -w
package NightGun::Store::Zbook;
use NightGun;
use NightGun::Store::Base;
use strict;

#use encoding "utf8";
my $PACKAGE_NAME="NightGun::Store::Zbook";
my $PATH_SEP='::';
my $PATH_EXP="^(.*)$PATH_SEP\/(.*)\$";
$PATH_EXP = qr/$PATH_EXP/;
my $FILE_EXP=qr/\.(:?zip|zbook|zjpg|zhtm)$/;
use MyPlace::Archive;

my %CACHED_BOOK;
my %cached_archive;

sub new {
	my ($class) = @_;
        my $self = bless {%{NightGun::Store::Base->new()},name=>"Zbook"},$class;
        $self->{handler} = MyPlace::Archive->new("unzip");
	return $self;
}
sub load {
    my ($self,$path) = @_;
    my $source = $path;
    my $entry = "";
	NightGun::message("Store::Zook","Loading $path");
	my ($source,$entry) = $self->parse_entry($path);
    return undef unless($source and $source =~ $FILE_EXP and -f $source);
    if(not defined $CACHED_BOOK{$source}) {
        unless($self->{handler}->test($source)) {
            $CACHED_BOOK{$source} = "no";
            return undef;
        }
        $self->list_archive($source);
        if(grep /\.(?:htm|html)$/i,@{$cached_archive{$source}{files}}) {
            $CACHED_BOOK{$source} = "yes";
        }
        else {
            $CACHED_BOOK{$source} = "no";
            return undef;
        }
    }
    else {
        return undef unless($CACHED_BOOK{$source} eq "yes");
    }
    $self->{save_history}=1;
LoadEntry:
    if($entry and $entry !~ /\/$/) {
        $self->{single}=1;
        $self->{name}=$path;
        $self->{parent}=$path;
        $self->{parent} =~ s/\/[^\/]+$/\//;
        $self->{url} = build_jar($source,$entry);
    }
    else { 
        my ($dirs,$files) = $self->list_archive($source,$entry);
        if(0 and (not $dirs) and  $files and @{$files} == 1) {
            if($files->[0] =~ $PATH_EXP) {
                $source = $1;
                $entry =$2;
            }
            $self->{single}=0;
            $self->{name}=$path;
            $self->{parent}=$path;
            $self->{parent} =~ s/\/[^\/]+$/\//;
            $self->{url} = build_jar($source,$entry);
            if($entry !~ /\//) {
                $self->{parent} =~ s/\/$//;
            }
            if($path =~ /\/$/) {
                $self->{parent} =~ s/\/[^\/]+\/$/\//;
            }
        }
        else {
            $self->{single}=0;
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
            $self->{default_entry}=undef;
            foreach(@{$files}) {
                if(/(:?aaa|index|content)\.(:?html|htm)/i) {
                    $self->{default_entry}=$_;
                    last;
                }
            }
            unless($self->{default_entry}) {
                $self->{url} = build_jar($source,$entry);
            }
        }
    }
    if($self->{parent} eq $source . "$PATH_SEP/" ) {
        my $l = length($self->{parent}) - length("$PATH_SEP/");
        $self->{parent} = substr($self->{parent},0,$l);
    }
    $self->{filetype}=$PACKAGE_NAME;
    $self->{location}=[$source,$entry ? $path : ""];
    $self->{title}=$self->{url};
    $self->{path}=$self->{name};
    return $self;
}

sub build_jar {
    return "jar:file:///" . join("!/",@_);
}

sub parse_entry {
    my $self = shift;
    my $path = shift;
    $path =~ s/^jar:file://ig;
    $path =~ s/^\/+/\//;
    $path =~ s/!\//$PATH_SEP\//;
    if($path =~ $PATH_EXP) {
        return $1,$2;
    }
    else {
        return $path,"";
    }
}
sub parse_location {
    my $self = shift;
    my $path = shift;
	NightGun::message("Store::Zbook","parse_location ",$path);
    $path =~ s/^jar:file://ig;
    $path =~ s/^\/+/\//;
    $path =~ s/!\//$PATH_SEP\//;
    if($path =~ $PATH_EXP) {
        return $1,$path;
    }
    else {
        return $path,"";
    }
}

sub list_archive {
    my ($self,$source,$entry,@cmds) = @_;
    
    my ($fh,@dirs,@files);
    $entry = "" unless($entry);
    if($entry) {
        $entry .= "/" unless($entry =~ /\/$/);
    }
    my (@c_dirs,@c_files);
    unless($cached_archive{$source}) {
        ($cached_archive{$source}{dirs},$cached_archive{$source}{files}) = 
            $self->{handler}->list($source);
    }
    @c_dirs = @{$cached_archive{$source}{dirs}};
    @c_files = @{$cached_archive{$source}{files}};
    my $filter = $entry ? qr/^$entry[^\/]+\/?$/ : qr/^[^\/\\]+\/?$/;
    @dirs = map {$source . $PATH_SEP . "\/" . $_} ( grep (/$filter/,@c_dirs));
    @files = map {$source . $PATH_SEP . "\/" . $_} ( grep (/$filter/,@c_files));
    return \@dirs , \@files;
}

1;
