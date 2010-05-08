#!/usr/bin/perl -w
package NightGun::Store::Archive;
use warnings;
use base qw/NightGun::Store/;
use MyPlace::Archive;
#use encoding "utf8";

my $PACKAGE_NAME="NightGun::Store::Archive";
my $PATH_SEP='::';
my $PATH_EXP="^(.*)$PATH_SEP\/(.*)\$";
$PATH_EXP = qr/$PATH_EXP/;
my %CACHED;
my %CACHED_BOOK;


sub _debug_print {print STDERR $@,"\n";};

sub new {
	my ($class,$solid_type) = @_;
	my $self = NightGun::Store::new($class);
    if($solid_type) {
    	my $handler = MyPlace::Archive->new($solid_type);
        $self->{ext1}=$handler if($handler);
	}
	return $self;
}

sub parse_location {
    my $self = shift;
    my $path = shift;
   # $path =~ s/^jar:file://g;
   	$path =~ s/^file://g;
	$path =~ s/^\/+/\//;
#	if(NightGun::Store->is_tempfile($self->{root},$path)) {
#		return ($self->{root},NightGun::Store->get_leaf($self->{root},$path));
#	}
    $path =~ s/%\/+/\//;
    $path =~ s/!\//$PATH_SEP\//;
    if($path =~ $PATH_EXP) {
        return $1,$path;
    }
    else {
		return $path,"";
		my $leaf = $self->get_leaf(
			$self->{root},
			$path);
		if($leaf) {
			$leaf = $self->{root} . $PATH_SEP . "/$leaf";
			return $self->{root},$leaf;
		}
		else {
	        return $path,"";
		}
    }
}

sub load {
    my ($self,$path,$data) = @_;
	return undef if($data);
    my $source = $path;
    my $entry = "";
    if($path =~ $PATH_EXP ) {
        $source = $1;
        $entry = $2;
    }
    return undef unless(-f $source);
    return undef if($CACHED_BOOK{$source} and $CACHED_BOOK{$source} eq "no");
    my $archive = $self->{ext1} ? $self->{ext1} : MyPlace::Archive->new($source);
    $CACHED_BOOK{$source} = "no" unless($archive);
    return undef unless($archive);
	$self->{type}=NightGun::Store::TYPE_STREAM;
    $self->{files}=undef;
	$self->{dirs}=undef;
	$self->{data}=undef;
	$self->{root}=$source;
	$self->{leaf}=$path;
LoadEntry:
    if($entry and $entry !~ /\/$/) {
        $self->{name}=$path;
        $self->{parent}=$path;
        $self->{parent} =~ s/\/[^\/]+$/\//;
        $self->{data}=$archive->extract($source,$entry);
		$self->{type}=NightGun::Store::TYPE_UNKNOWN;
#		if($self->type_what($entry) eq $self->TYPE_URI) {
#			my $tmpfile = $self->get_tempfile($source,$entry);
#			if(open FO,">",$tmpfile) {
#				print FO $self->{data};
#				close FO;
#				$self->{data}=$tmpfile;
#				$self->{type}=$self->TYPE_URI;
#			}
#			else {
#				die("MMMMMMMMMMMMMMMMMMm$!\n");
#			}
#		}
    }
    else { 
        my ($dirs,$files) = $self->list_archive($archive,$source,$entry);
            $self->{files} = $files;
            $self->{dirs} = $dirs;
        if(@{$CACHED{$source}->{dirs}} == 0 and @{$CACHED{$source}->{files}} == 1) {
            $self->{data} = $archive->extract($source,$CACHED{$source}->{files}->[0]);
			#_debug_print $self->{data};
			$self->{files}=undef;
			$self->{dirs}=undef;
			$self->{type}=NightGun::Store::TYPE_UNKNOWN;
        }
        else {
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
    $self->{title} = $path;
    $self->{id} = $path;
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
