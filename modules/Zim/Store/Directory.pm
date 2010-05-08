package Zim::Store::Directory;

use strict;
use File::MimeInfo;
use vars qw/$CODESET/;
use Zim::Utils;
use Zim::Store::Cached;
use File::Temp qw/tempfile/;
use File::Spec;
use File::Glob qw/:glob/;
use Encode;
#use Data::Dumper;

our $VERSION = '0.24';
our @ISA = qw/Zim::Store::Cached/;
*CODESET = \$Zim::CODESET;
$CODESET ||= 'utf8';

=head1 NAME

Zim::Store::Directory - A directory system based store

=head1 DESCRIPTION

This module implements a file system based store for zim.
See L<Zim::Store> for the interface documentation.

=head1 METHODS

=over 4

=item C<new(PARENT, NAMESPACE, DIR)>

Simple constructor. DIR is the root directory of the store.
NAMESPACE is the namespace that maps to that directory.

=cut

sub init {
#warn "init(@_)\n"; # called by new
	my $self = shift;
	$self->check_dir;

	$self->{read_only} = $self->root->{config}{read_only}
	                  || (-w $self->{dir}) ? 0 : 1;
	$self->{format} ||= 'text';
        #$self->root->{config}{home} = ":/";
        $self->{home} = $self->root->{config}{home};
        $self->{name} = $self->root->{config}{name};
	$self->{ext} = ($self->{format} eq 'html')     ? 'html' :
	               ($self->{format} eq 'pod')      ? 'pod'  :
	               ($self->{format} eq 'txt2tags') ? 't2t'  : 
                       ($self->{format} eq 'text')     ? 'txt'  : 'txt';
		# FIXME HACK FIXME - this belongs in a Formats.pm
	
	$self->SUPER::init();
	return $self;
}

sub _search {
#warn "_search(@_)\n"; # query is a hash ref with options etc
	my ($self, $query, $callback, $ns) = @_;
	$ns ||= $self->{namespace};
#warn "Searching $ns\n";
	
	my $reg = $$query{regex};
	unless ($reg) {
		$reg = quotemeta $$query{string};
		$reg = "\\b".$reg."\\b" if $$query{word};
		$reg = "(?i)".$reg unless $$query{case};
		$reg = qr/$reg/;
#warn $reg;
		$$query{regex} = $reg;
	}
	
	for ($self->list_pages($ns)) {
		my $p = $ns.$_;
		my $is_dir = ($p =~ s/:$//);
		my $match = ($p =~ $reg) ? 1 : 0 ;
		$match += $self->page2file($p)->grep($reg, 'count');
		$callback->($match ? [$p, $match] : ());
		$self->_search($query, $callback, $p.':') if $is_dir; # recurs
	}
}

=item C<get_page(PAGE_NAME)>

Returns an object of the type L<Zim::Page>.

=cut

my %cached_page;
sub get_page {
warn "get_page(@_)\n";
	my ($self, $name, $source) = @_; # source is a private argument
        return $cached_page{$name} if($cached_page{$name});
	$source ||= $self->page2file($name); # case sensitive lookup
	my $page = Zim::Page->new($self, $name);
	$page->{properties}{read_only} = $$self{read_only} || !$source->writable;
        if($name eq $$self{home}) {
warn "-->Home page<--\n";
            $page = $self->create_dir_page($page,$$self{dir});
        }
        elsif($source =~ /^(.*)\/\!(.*)$/) {
warn "-->Archive page<--\n";
                $page = $self->create_archive_page($page,$source,$1,$2);
        }
        elsif(-f $source) {        
warn "-->File page<--\n";
            $page = $self->get_file_page($page,$source);
        }
        elsif(-d $source) {
            my ($src) = grep {-f $_} ("$source.txt","$source/Home.txt");
            if($src) {
warn "-->Directory Wiki page<--\n";
                $page->set_source(file($src));
                $page->set_format("wiki");
            }
            else {
warn "-->Directory page<--\n";
                $page = $self->create_dir_page($page,$source);
            }
        }
        elsif(-f $source . ".txt") {
warn "-->File Wiki page<--\n";
            $page->set_source(file($source . ".txt"));
            $page->set_format("wiki");
        }
        elsif($source =~ /\/$/) {
warn "-->Directory page<--\n";
            $page = $self->create_dir_page($page,$source);    
        }
        else {
warn "-->New page<--\n";
            $page->set_source($source);
            $page->set_format($self->{format});
	    $page->{parse_tree} = $self->_template($page);
	    $page->status('new');
	}
        $cached_page{$name} = $page if($page && $page->{cachable});
#use Data::Dumper;warn "get_page:\n",Dumper($page),"\n";
warn "get_page: ", $page ? $page->{name} . " ==> " . $page->{source} : "$name ==> empty","\n";
	return $page;
}

sub new_tmp_file {
#warn "new_tmp_file(@_)\n";
    my ($self,$suffix) = @_;
    $suffix =~ s/\//_/g;
    my ($fh,$fn) = tempfile("xrzreader-XXXXXX",DIR=>File::Spec->tmpdir(),SUFFIX=>$suffix);
    close $fh;
    return file($fn);
}

sub create_link {
#warn "create_link(@_)\n";
    my ($self,$path) = @_;
    my $text = $path; $text =~ s/^.*\/+//g;
    my $link = $path; $link =~ s/\//:/g; 
    return "* [[:$link|$text]]\n";
}

sub create_files_text {
    my ($self,$dir,$rel_dir,@files) = @_;
    my @text;
    foreach(@files) {
        if(/\.zbook$/i) {
            push @text,"* [[zhreader://$dir/$_|$_]]\n";
        }
        elsif(/\.(:?jpg|jpeg|png|gif)$/i) {
            push @text,"{{$_}}\n\n";
        }
        elsif(/\.(:?rmvb|rm|wmv|avi|mkv)$/i) {
            push @text,"* [[mplayer://$dir/$_|$_]]\n";
        }
        else {
            push @text,"* [[$rel_dir:$_|$_]]\n";
        }
    }
    return @text;
}
sub create_dir_page {
    my ($self,$page,$dir) = @_;
    mkdir $dir unless(-d $dir);
    my $source;
        my $name = $dir; $name =~ s/\/+$//g; $name =~ s/^.*\///g; $name = ucfirst($name);
        my $basedir = $dir;$basedir =~ s/\/+$//g;
        my $globdir = $basedir;$globdir =~ s/([ \*\?\[\]\{\}])/\\$1/g;
        my $rel_dir = $$self{dir};$rel_dir =~ s/\/+$//g;$rel_dir = substr($basedir,length($rel_dir));
        $rel_dir =~ s/\//:/g;
        my (@dirs, @files);
        foreach(map {s/([\|])/sprintf("%%%04X",ord($1))/eg;decode("utf8",$_);} bsd_glob("$globdir/*")) {
#warn "create_dir_page get: $_\n";
            if(-f $_) {push @files,$_;} else {push @dirs,$_;}
        }
        @files = map {s/^.*\///g;$_;} @files;
        @dirs = map {s/^.*\///g;$_;} @dirs;
        $source = $self->new_tmp_file($name);
        my $fo = $source->open('w');
        print $fo  "====== $name ======\n\n";
        if(@dirs) {
            print $fo  "== Directories: ==\n";
            print $fo (map "* [[$rel_dir:$_|$_]]\n",@dirs),"\n";
        }
        if(@files) {
            print $fo  "== Files: ==\n";
            print $fo  $self->create_files_text($basedir,$rel_dir,@files);
        }
        $fo->close();
    $page->set_source($source);
    $page->set_format("wiki");
    return $page;
}

sub get_file_page {
    my ($self,$page,$source) = @_;
    my $ext = $source; $ext =~ s/^.*\.([^\.]+)$/$1/; $ext = $ext ? lc($ext) : "";
    if($ext eq "tar" || $ext eq "tgz" || $source =~ /\.tar\.\w+$/) {
        $page = $self->get_list_page($page,$source,$self->list_tar($page,$source));
    }
    elsif($ext eq "zip") {
        $page = $self->get_list_page($page,$source,$self->list_zip($page,$source));
    }
    elsif($ext eq "rar") {
        $page = $self->get_list_page($page,$source,$self->list_rar($page,$source));
    }
    elsif($ext eq "gz") {$page = $self->create_gz_page($page,$source);}
    elsif($ext eq "bz" || $ext eq "bz2") {$page = $self->create_bz_page($page,$source);}
    elsif($ext eq "xml") {
        $page->set_source($source);
        $page->set_format("xml");
        $page->{properties}{readonly}=1;
        $page->{cachable}=1;
    }
    elsif($ext eq "wiki") {
        $page->set_source($source);
        $page->set_format("wiki");
    }
    elsif($ext eq "html") {
        $page->set_source($source);
        $page->set_format("txt");
    }
    else{
	$page->set_source($source);
	$page->set_format($self->{format});
    }
    return $page;
}

sub get_list_page {
    my ($self,$page,$source,$dirs,$files,$prefix) = @_;
    my $name = $page; $name =~ s/^.*://;
    $prefix = "" unless($prefix);
    if((!$dirs) && $files && @{$files} eq "1") {
       return $self->create_archive_page($page,$source,$source,$files->[0]);
    }
    my $text = "";
    $text .= "="x6 . " " . ucfirst($name) . " " . "="x6 . "\n\n";
    if($dirs) {
        $text .= "== Directories: ==\n";
        $text .= join("", (map "* [[$prefix$_|$_]]\n",@{$dirs}));
        $text .= "\n";
    }
    if($files) {
        $text .= "== Files: ==\n";
        $text .= join("",(map "* [[$prefix$_|$_]]\n",@{$files}));
    }
#warn $text;
    $page->set_format("wiki");
    my $fh = buffer(\$text)->open('r'); 
    $page->{parse_tree} = $page->{format}->load_tree($fh,$page);
    close $fh;
    $page->{properties}{readonly}=1;
    $page->{cachable}=1;
    return $page;
}

sub create_archive_page {
#warn "create_archive_page(@_)\n";
    my ($self,$page,$source,$archive,$entry) = @_;
   my($dirs,$files,$prefix,$src);
    if($archive =~ /\.(:?tar|tgz|tar\.\w+)$/i) {
        ($dirs,$files,$prefix) = $self->list_tar($page,$archive,$entry);
        if(($dirs && @{$dirs}) || $files && @{$files}) {
            return $self->get_list_page($page,$source,$dirs,$files,$prefix);
        }
        $src = $self->create_pipe_file($entry,"tar","-af",$archive,"-x",$entry,"-O");
    }
    elsif($archive =~ /\.zip$/i) {
        ($dirs,$files,$prefix) = $self->list_zip($page,$archive,$entry);
        if(($dirs && @{$dirs}) || $files && @{$files}) {
            return $self->get_list_page($page,$source,$dirs,$files,$prefix);
        }
        $src = $self->create_pipe_file($entry,"unzip","-p",$archive,$entry);
    }
    elsif($archive =~ /\.rar$/i) {
        ($dirs,$files,$prefix) = $self->list_rar($page,$archive,$entry);
        if(($dirs && @{$dirs}) || $files && @{$files}) {
            return $self->get_list_page($page,$source,$dirs,$files,$prefix);
        }
        $src = $self->create_pipe_file($entry,"unrar","p","-inul",$archive,$entry);
    }
    $page = $self->get_file_page($page,$src) if($src);
    $page->{properties}{readonly}=1;
    $page->{cachable}=1;
    return $page;
}

{my %cached_archive;
sub list_archive {
    my ($self,$page,$source,$entry,@cmds) = @_;
    my ($fh,$prefix,@dirs,@files);
    my ($rel_dir,$basedir) = ($$self{dir},$source);
    $rel_dir =~ s/\/+$//g; $rel_dir = substr($basedir,length($rel_dir));
    $entry = "" unless($entry);
    if($entry) {
        $entry .= "/" unless(/\/$/);
    }
    $prefix = "$rel_dir\/!$entry";
    $prefix =~ s/\//:/g;
#warn $prefix,"\n";
    my (@c_dirs,@c_files);
    if($cached_archive{$source}) {
        @c_dirs = @{$cached_archive{$source}{dirs}};
        @c_files = @{$cached_archive{$source}{files}};
    }
    else {
        open $fh,"-|:utf8",@cmds or die("$!\n");
        while(<$fh>) {
#warn $_;
            chomp;
            if(/\/$/) {
                s/\/$//g;
                push @c_dirs,$_;
            } 
            else {
                push @c_files,$_;
            }
        }
        close $fh;
        $cached_archive{$source}{dirs}=\@c_dirs;
        $cached_archive{$source}{files}=\@c_files;
    }
    @dirs = map {s/^$entry//;$_} (grep /^$entry[^\/]+\/?$/,@c_dirs);
    @files = map {s/^$entry//;$_} (grep /^$entry[^\/]+\/?$/,@c_files);
    return @dirs ? \@dirs : undef,@files ? \@files : undef,$prefix;
}}

sub list_tar {
    my ($self,$page,$source,$entry) = @_;
    return $self->list_archive($page,$source,$entry,"tar","-taf",$source);
}
sub list_zip {
    my ($self,$page,$source,$entry) = @_;
    return $self->list_archive($page,$source,$entry,"unzip","-Z1",$source);
}
sub list_rar {
    my ($self,$page,$source,$entry) = @_;
    return $self->list_archive($page,$source,$entry,"unrar","lb",$source);
}

sub create_bz_page {
#warn "create_bz_page(@_)\n";
    my ($self,$page,$gz_src) = @_;
    my $source = $gz_src;$source =~ s/\.bz\d*$//i;$source =~ s/^.*\///;
    $source = $self->create_pipe_file($source,"bzip2","-c","-d",$gz_src);
    $page = $self->get_page($page->{name},$source);
    $page->{properties}{readonly}=1;
    $page->{cachable}=1;
    return $page;
}
sub create_gz_page {
#warn "create_gz_page(@_)\n";
    my ($self,$page,$gz_src) = @_;
    my $source = $gz_src;$source =~ s/\.gz$//i;$source =~ s/^.*\///;
    $source = $self->create_pipe_file($source,"gzip","-c","-d",$gz_src);
    $page = $self->get_page($page->{name},$source);
    $page->{properties}{readonly}=1;
    $page->{cachable}=1;
    return $page;
}

sub create_pipe_file {
    my ($self,$name,@cmd) = @_;
    my $dstfile = $self->new_tmp_file($name);
    open FI,"-|",@cmd or die("Can't not fork @cmd\n");
    open FO,">",$dstfile;
    while(<FI>) {print FO $_;}
    close FO;close FI;
    return $dstfile;
}



sub resolve_case {
#warn "resolve_case(@_)\n";
#warn("Store::Files->resolve_case(@_)","\n");
	# TODO use the cache for this lookup !
	my ($self, $link, $page) = @_;
	my $match;
	if ($page and @$page) {
#warn "resolve_case: @$link @ @$page\n";
		my $anchor = shift @$link;
		for (reverse  -1 .. $#$page) {
			my $t = ':'.join(':', @$page[0..$_], $anchor);
#warn "\ttrying: $t\n";
			my $file = $self->page2file($t, 1) or next;
#warn "FOUND FILE: $file\n";
			my $dir = $file;
			$dir =~ s/\Q$$self{ext}\E$//;
			next unless -f $file or -d $dir;
			$match = join ':', $t, @$link;
			last;
		}
	}
	else { $match = ':' . join ':', @$link } # absolute

	return undef unless $match;
	my $file = $self->page2file($match, 1);
	return $self->file2page($file);
}


sub _template {
#warn "_template(@_)\n";
	# FIXME should use Zim::Formats->bootstrap_template()
	my ($self, $page) = @_;

	# Name of the template to use
	my $name = ("$page" =~ /^:Date:/) ? '_Date' : '_New' ;
		# FIXME HACK - should use Namespace setting of Calendar
		#              should not hardcode plugin here !

	# Do the template lookup once and cache the resulting template object
	# we can re-use template objects to generate many pages
	my $key = "_template_$name";
	unless (defined $$self{$key}) {
		my $template = Zim::Formats->lookup_template($$self{format}, $name);
		if ($template) {
			require Zim::Template;
			$$self{$key} = Zim::Template->new($template);
		}
		else { $$self{$key} = 0 } # defined FALSE - no template
	}

	# Set template parameter
	my $title = $page->basename;
	$title = ucfirst($title) unless $title =~ /[[:upper:]]/;
	$title =~ s/_/ /g;

	# Hard coded default when no template is defined
	# we do it like this because needs to be syntax independent here
	return ['Page', {%{$page->{properties}}}, ['head1', {}, $title]]
		unless $$self{$key};

	# Process template
	my $text;
	my $data = { page => { title => $title, name => $page->name } };
		# FIXME FIXME FIXME use real page object
	$$self{$key}->process($data => \$text);
	
	# Parse the generated page contents and return parse tree
	my $fh = buffer(\$text)->open('r');
	my $tree = $page->{format}->load_tree($fh, $page);
	close $fh;

	%{$tree->[1]} = (%{$page->{properties}}, %{$tree->[1]});
	return $tree;
}


sub copy_page {
#warn "copy_page(@_)\n";
	my ($self, $old, $new, $update) = @_;
	my $source = $self->page2file($old);
	my $target = $self->page2file($new);
	$source->copy($target);
	@$new{'status', 'parse_tree'} = ('', undef);
	if ($update) {
		my ($from, $to) = ($source->name, $target->name);
		$self->get_page($_)->update_links($from => $to)
			for $source->list_backlinks ;
	}
}


sub move_page {
#warn "move_page(@_)\n";
	my ($self, $old, $new) = @_;
	
	# Move file
	my $source = $self->page2file($old);
	my $target = $self->page2file($new);

	die "No such page: $source\n" unless $source->exists;
#warn "Moving $source to $target\n";
	$source->move($target);
	$source->cleanup unless $source->exists;
		# When renaming a file to a different case on file-system
		# that is not case-sensitive source now points to the same
		# file as target - do not delete it !

	# update objects
	@$old{'status', 'parse_tree'} = ('deleted', undef);
	@$new{'status', 'parse_tree'} = ('', undef);
	$self->_cache_page($old);
	$self->_cache_page($new);
}


sub delete_page {
#warn "delete_page(@_)\n";
	my ($self, $page) = @_;

	my $file = $self->page2file($page);
	$file = $self->page2dir($page) unless $file->exists;
		# border case where empty dir was left for some reason
		# and user tries to delete new page from index
	$file->cleanup;
	@$page{'status', 'parse_tree'} = ('deleted', undef) if ref $page;
	$self->_cache_page($page);
}

sub search {
#warn "search(@_)\n";
	my ($self, $page, $query) = @_;
	
}

sub page2file {
#warn "page2file(@_)\n";
	my ($self, $page, $case_tolerant) = @_;
#warn "Looking up filename for: $page\n";
        
	if (ref $page) {
		return $page->{source} if defined $page->{source};
		$page = $page->name;
	}
	# Special case for top level
	if ($page eq $self->{indexpage}) { $page = '_index' }
	else { $page =~ s/^\Q$$self{namespace}\E//i }

	# Split and decode
	#map {s/([^[:alnum:]_\.\-\(\)])/sprintf("%%%02X",ord($1))/eg; $_}
	my @parts =
		map {s/\%([A-Fa-z0-9]{4})/chr(hex($1))/eg; $_}
		grep length($_), split /:+/, $page;

	# Search file path
	my $file = @parts ? $$self{dir}->file(@parts) : $$self{dir};
#warn "\t=> $file\n";

	# Re-bless file object
	$file = $self->root->{config}{slow_fs}
		? Zim::FS::File::CacheOnWrite->new($file)
		: Zim::FS::File::CheckOnWrite->new($file) ;
	return $file;
}

sub page2dir {
#warn "page2dir(@_)\n";
	my ($self, $page, $case_tolerant) = @_;
	$page = $page->name if ref $page;

	if ($page eq $self->{indexpage}) { return $$self{dir} }
	else { $page =~ s/^\Q$self->{namespace}\E//i }
	my @parts =
		map {s/\%([A-Fa-z0-9]{2})/chr(hex($1))/eg; $_}
		grep length($_), split /:+/, $page;

	my $dir = $case_tolerant
		? $$self{dir}->resolve_dir($$self{ext}, @parts)
		: $$self{dir}->subdir(@parts) ;

	return $dir;
}

=item C<file2page(FILE)>

Returns the page name corresponding to FILE. FILE does not actually
need to exist and can be a directory as well as a file.

=cut

sub file2page {
#warn "file2page(@_)\n";
        my $page;
	my ($self, $file) = @_;
#warn "looking up page name for: $file\n";
	$file = Zim::FS->rel_path($file, $$self{dir});
	$file =~ s/.\///;
	my @parts =
		map {s/([\|])/sprintf("%%%04X",ord($1))/eg; $_}
		grep length($_), split /[\/]+/, $file;
	return undef unless @parts;
#	$parts[-1] =~ s/\.\Q$$self{ext}\E$//;
	if($parts[-1] =~ /^_index$/i) {
    	    $page=$self->{indexpage};
        }
        else {
	    $page=$self->{namespace} . join ':', @parts;
        }
#warn "\t===>$page\n";
        return $page;
}

1;

