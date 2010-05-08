package NightGun::Store::Files;
use NightGun;
use Encode qw/decode/;
use Term::ANSIColor;
use base NightGun::Store;
use strict;

sub new {
	return NightGun::Store::new(@_);
}

sub load {
    my ($self,$path,$data) = @_;
	return undef if($data);
	NightGun::message("Store::Files","load $path...");
    $path =~ s/\/$//g;
    $path = "/" unless($path);
	unless($data or -e $path) {
		return undef;
	}
	if($data) {
       $self->{files}=undef;
	   $self->{dirs}=undef;
		$self->{type}=$self->type_what($path);
		$self->{data}=$data;
	}
    elsif(-f $path) {
       if($path =~ /^(.*)\/[^\/]+$/) {
            ($self->{root},$self->{leaf})=($1,$path);
       }
       else {
            ($self->{root},$self->{leaf})=($path,undef);
       }
       $self->{files}=undef;
	   $self->{dirs}=undef;
		$self->{type}=$self->type_what($path);
		if($self->{type} == NightGun::Store->TYPE_STREAM) {
           open FI,"<",$path or return;
           $self->{data}=join("",<FI>);
           close FI;
        }
		else {
			$self->{data}=$path;
		}
    }
    else {
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
    $self->{parent} =~ s/\/[^\/]*$//;
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

