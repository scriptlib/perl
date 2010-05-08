package Zim;

sub new {
	my ($class, %param) = @_;

	$param{namespace} ||= ':';
	$param{namespace} =~ s/:?$/:/;
	die "BUG: store initialized without directory"
		unless $param{dir};
	$param{dir} = dir($param{dir}) unless ref($param{dir});
	die "No such directory: $param{dir}\n" unless $param{dir}->exists;
	
	my $self = bless {%param}, $class;
	$self->{config} ||= {};

	# Read config
	$$self{config_file} = $class->get_notebook_config($param{dir});
	$$self{config_file}->read($$self{config}, 'Notebook');
	$self->signal_connect(config_changed => \&_init_properties, $self);
	$self->_init_properties;

	# Set default store if not yet defined
	my $type = $self->{config}{type} || 'Directory';
	$self->add_child(':', $type, %param)
		unless defined $self->{config}{':'};

	# Initialize stores defined in config
	for my $ns (sort keys %{$self->{config}{Namespaces}}) {
		# remove namespace defnitions from config
		# allows lines like ":namespace=Class,key=val,key=val"
		my $val = $self->{config}{Namespaces}{$ns};
		my ($class, $arg) = split ',', $val, 2;
		my %arg = map split('=',$_,2),
		          map split(',',$_,2), $arg; 
		$self->add_child($ns => $class, %arg);
	}
	
	return $self;
}

sub _check_page_name {
        return 1;
	croak "\"$_[0]\" is not a valid page name"
		unless $_[0] =~ /^(?::+[\w\%\!\[\]]+[\w\!\[\]\.\-\(\)\%]*)+$/;
}

sub _check_namespace {
        return 1;
	croak "\"$_[0]\" is not a valid namespace"
		unless $_[0] =~ /^(?::+|(?::+[\w\%\!\[\]][\w\!\[\]\.\-\(\)\%]*)+:+)$/;
}

sub get_notebook_config {
	my ($class, $dir) = @_;
	my ($file) = grep {-e $_}
	             map  "$dir/$_", qw/notebook.xrz .notebook.xrz/;
	$file = "$dir/notebook.xrz" unless defined $file;
	return Zim::FS::File::Config->new($file);
}

sub get_notebook_cache {
	my ($class, $dir) = @_;

	# If dir is an object already it can have a property "slow_fs"
	# FIXME should we check notebook.xrz for this property if we
	# get a path ?
	unless (ref($dir) and $$dir{slow_fs}) {
		my $cache = dir( $dir."/.xrz" );
		# do not use subdir here - cache should e.g. not be under VCS
		return $cache if $cache->writable;
	}
	
	# logic similar to login in cache_file() in FS.pm
	my $name = Zim::FS->abs_path($dir);
	$name =~ s/[\/\\:]+/_/g; # win32 save
	$name =~ s/^_+|_+$//g;
	return dir(xdg_cache_home(), 'xrzReader', $name);
}

sub get_notebook {
	my ($class, $name) = @_;
	
	if ($name eq '_doc_') {
		my $path = data_dirs(qw/xrzReader doc/);
		return dir( $path );
	}

	my ($n, $m);
	my @list = reverse $class->get_notebook_list;
	for (@list) {
		# do lookup both exact and case-insensitive
		if    ($$_[0] eq $name        ) { $n = $$_[1] }
		elsif (lc($$_[0]) eq lc($name)) { $m = $$_[1] }
	}
	$n ||= $m;
	return undef unless $n;

	return $class->get_notebook($n)
		if $name eq '_default_' and $n !~ /[\\\/]/;
		# recurs when default is not a path but a name

	return dir($n) ;
}

sub get_notebook_list {
	shift; # class
	my $file = config_files('xrzReader', 'notebooks.list');
	$file ||= config_files('xrzReader', 'repositories.list');
		# backwards compatibility to versions < 0.23
	return () unless defined $file;
	my @notebooks = grep defined($_), map {
		/^((?:\\.|\S)+?)[=\s]+(.+?)\r?\n/
			? [$1 => $2] : undef ;
	} file($file)->read;
		# allow "=" as separator instead of whitespace
		# for backwards compatibility to versions < 0.24
	$$_[0] =~ s/\\([\s\\])/$1/g for @notebooks; # unescape whitespace
	return @notebooks
}

sub set_notebook_list {
	shift; # class
	my @lines = map {
		my ($name, $path) = @$_;
		$name =~ s/([\s\\])/\\$1/g; # escape whitespace
		"$name\t$path\n";
	} @_;
	my $file = config_home('xrzReader', 'notebooks.list');
	file($file)->write(@lines);
}

1;

