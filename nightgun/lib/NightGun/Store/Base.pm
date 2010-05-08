package NightGun::Store::Base;
use NightGun;
use Encode qw/decode/;
use Term::ANSIColor;

my $NO_PLAIN_TEXT = qr/\.(:?html|htm|png|jpeg|jpg|gif|asp|rm|rmvb|avi|xml|mkv|doc|mp3)$/;
sub new {
	my ($class, $parent) = @_;
	my $self = bless {
		name => undef,
                title => undef,
                location=>["",""],
                path=>undef,
                directories => [],
                files => [],
                parent => undef,
                text => undef,
                filetype => undef,
                handler => undef,
                single => undef,
                save_history=>undef,
                url => undef,
	}, $class ;
	return $self;
}
sub load {
    my ($self,$path) = @_;
    $path =~ s/\/$//g;
    $path = "/" unless($path);
    $self->{single}=0;
    if(-f $path) {
        if($path =~ $NO_PLAIN_TEXT) {
            $self->{url}=$path;
        }
        else {
           open FI,"<",$path or return;
           $self->{text}=join("",<FI>);
           close FI;
        }
       if($path =~ /^(.*)\/[^\/]+$/) {
            $self->{location}=[$1,$path];
       }
       else {
            $self->{location}=[$path,""];
       }
       $self->{single}=1;
    }
    else {
        $self->{files}=[];
        $self->{directories}=[];
        foreach(map {decode("utf8",$_)} glob($path . "/*")) {
            if(-f $_) {
                push @{$self->{files}},$_;
            }
            else {
                push @{$self->{directories}},$_;
            }
        }
        $self->{text}="";
        $self->{location}=[$path,""];
#        if((@{$self->{files}} eq 1) and (@{$self->{directories}} eq 0)) {
#            $self->{single}=1;
#        }
    }
    $self->{path}=$path;
    $self->{parent}=$self->{location}->[0];
    $self->{parent} =~ s/\/[^\/]*$//;
    $self->{title} = $path;
    $self->{filetype}="Default";
    $self->{handler}=undef;
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

