package NightGun::Store;
#use NightGun;
use Term::ANSIColor;
use File::Temp qw/tempdir/;
use fields qw/id root leaf title parent files dirs data type name ext1 ext2 donot_encode donot_escape/;

my $NO_PLAIN_TEXT = qr/\.(:?pdf|swf|flv|gs|ps|html|htm|png|jpeg|jpg|gif|asp|rm|rmvb|avi|xml|mkv|doc|mp3)$/i;

my $tempfile_id=0;
my %maps;

sub TYPE_UNKNOWN {0;}

sub TYPE_URI {1;}
sub TYPE_STREAM {2;}
sub TYPE_RELOAD {3;}

sub TYPE_HTML_DATA {4;}
sub TYPE_TEXT_DATA {5;}
sub TYPE_HTML_URI {6;}
sub TYPE_TEXT_URI {7;}

sub load {
	my($self,$path,$data)=@_;
	return undef if($data);
	$self->{type}=TYPE_STREAM;
	$self->{data}="Unknown type:\n" . $path;
	$self->{files}=undef;
	$self->{dirs}=undef;
	$self->{id}=$path;
	$self->{root}=$path;
	$self->{leaf}=undef;
	$self->{title}="Unknown type\n";
	return $self;
}
sub new {
	my $class = shift;
	my $self = fields::new($class) unless(ref $class);
	$self->{name}=$class unless(ref $class);
	return $self;
}

sub type_what {
	my ($self,$filename)=@_;
	return TYPE_URI if(lc($filename) =~ $NO_PLAIN_TEXT);
	return TYPE_STREAM;
}

sub is_single {
	my $self=shift;
	return undef if($self->{files} || $self->{dirs});
	return 1;
}

sub have_history {
	my $self = shift;
	return 1 if($self->{leaf});
	return 0;
}

sub get_tempfile {
	my ($self,$root,$leaf) = @_;
	my $prefix;
	if($maps{$root}) {
		$prefix = $maps{$root}->{':ROOT:'};
	}
	else {
		$prefix = tempdir(CLEANUP=>1);
		$maps{$root}->{':ROOT:'}=$prefix;
	}
	my $r = $leaf;
	$r =~ s/[\/:!\?\*%\(\)\[\]\{\}]/_/g;
	$r = "$prefix/$r";
	$maps{$root}->{$r}=$leaf;
	NightGun::message("Store","get_tempfile $r");
	return $r;
}

sub is_tempfile {
	my ($self,$root,$filename) = @_;
	return undef unless($maps{$root});
	return 1 if($maps{$root}->{$filename});
	my $prefix = $maps{$root}->{':ROOT:'};
	my $lp = length($prefix);
	if(substr($filename,0,$lp) eq $prefix) {
		return 1;
	}
	return undef;
}

sub get_leaf {
	my ($self,$root,$filename) = @_;
	return $maps{$root}->{$filename} if($maps{$root} && $maps{$root}->{$filename});
	my $prefix = $maps{$root}->{':ROOT:'};
	my $lp = length($prefix);
	if(substr($filename,0,$lp) eq $prefix) {
		return substr($filename,$lp+1);
	}
	else {
		return undef;
	}
}

sub destory {
	File::Temp::cleanup;
}

1;

