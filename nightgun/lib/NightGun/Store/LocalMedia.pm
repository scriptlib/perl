package NightGun::Store::LocalMedia;
use NightGun;
use Encode qw/decode/;
use Term::ANSIColor;
use base NightGun::Store;
use strict;

my $LOCAL_MEDIA = qr/\.(:?pdf|swf|flv|gs|ps|html|htm|png|jpeg|jpg|gif|asp|rm|rmvb|avi|mkv|doc|mp3)$/i;
my $PLAIN_TEXT = qr/\.(:?txt|text|conf|rc|desktop|pl|sh|py|c|cpp|h|hh|hpp)$/i;

sub new {
	return NightGun::Store::new(@_);
}

sub load {
    my ($self,$path,$data) = @_;
    return undef if($data or (! -e $path));
    NightGun::message("Store::LocalMedia","load $path...");
    $path =~ s/\/$//g;
    $path = "/" unless($path);
    if(-f $path) {
        #print STDERR "is a file","\n";
        if($path =~ /$PLAIN_TEXT/i) {
            #print STDERR "is a file which is plain text","\n";
            $self->{type} = NightGun::Store->TYPE_STREAM;
            open FI,"<",$path or return;
            $self->{data}=join("",<FI>);
            close FI;
        }
        elsif($path =~ /$LOCAL_MEDIA/i) {
            #print STDERR "is a file which is local media","\n";
            $self->{type} = NightGun::Store->TYPE_URI;
            $self->{data} = $path;
        }
        else {
            #print STDERR "is a file but can't be handled","\n";
            return undef;
        }
        if($path =~ /^(.*)\/[^\/]+$/) {
            ($self->{root},$self->{leaf})=($1,$path);
        }
        else {
            ($self->{root},$self->{leaf})=($path,undef);
        }
        $self->{files}=undef;
	$self->{dirs}=undef;
    }
    else {
        #print STDERR "is a directory","\n";
	$self->{type} = NightGun::Store->TYPE_STREAM;
        $self->{files}=[];
        $self->{dirs}=[];
		use File::Glob qw/:glob/;
		#print STDERR $path,":\n";
        foreach(glob($path . "/*")) {
        #foreach(map {decode("utf8",$_)} glob($path . "/*")) {
			#print STDERR $_,"\n";
            if(-f $_) {
                push @{$self->{files}},$_;
            }
            else {
                push @{$self->{dirs}},$_;
            }
        }
        $self->{data}=undef;
        $self->{root}=$path;
	$self->{leaf}=undef;
    }
    $self->{id}=$path;
    $self->{parent}=$self->{root};
    $self->{root}=$self->{root} . "/";
    $self->{parent} =~ s/\/[^\/]+$/\//;
    $self->{title} = $self->{id};
    $self->{title} =~ s/.*\///g;
    return $self;
}
sub parse_location {
    my $self=shift;
    my $path=shift;
    $path =~ s/^file://g;
    $path =~ s/^\/+/\//;
        if($path =~ /\/$/) {
            $path = substr($path,0,length($path)-1);
        }
        if($path =~ /^(.*)\/[^\/]+$/) {
            return $1,$path;
        }
        else {
            return $path,"";
        }
}
1;

