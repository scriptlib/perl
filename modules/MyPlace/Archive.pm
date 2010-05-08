#!/usr/bin/perl -w
package MyPlace::Archive;
use strict;
use warnings;

my $PACKAGE_NAME="MyPlace::Archive";
my  @filetype;
my  @def_filetype = qw/Zip Rar 7zr Tar Bzip2 Gzip 7za 7z/;
my @handlers = ();
my %CACHED;
my $DEBUG=1;
use overload 
    'bool'=>sub {$_[0]->{valid}},
    '""'=>sub {
        my $self=shift;
        if($self->{valid}) {
            return $self->{name} . "::" . $self->{handler}->{name};
        }
        else {
            return $self->{name} . "::" . "Invalid";
        }
    },
    ;

sub import {
    shift;
	my %arg = @_;
    if(%arg) {
        @filetype=@{$arg{filetype}};
		$DEBUG = $arg{DEBUG};
    }
    else {
        @filetype=@def_filetype;
    }
}

sub new {
	my ($class,$source) = @_;
	my $self = bless {name=>"MyPlace::Archive",valid=>0}, $class ;
        _build_handlers() unless(@handlers);
        if($self->_cached_load($source,"valid")) {
            $self->_cached_load($source,"handler");
            $self->_cached_load($source,"filetest");
            $self->_cached_load($source,"filelist");
            return $self;
        }
        if(-f $source) {
            #my $len=length($source);
			foreach my $level (1,2) {
	            foreach my $hnd (@handlers) {
					if($self->handler_test($hnd,$source,$level)) {
                		$self->{handler}=$hnd;
						$self->{valid}=1;
						$self->{filename}=$source;
						goto file_handler_found;
					}
            	}
			}
file_handler_found:
            $self->_cached_save($source,"valid");
            $self->_cached_save($source,"handler");
            return $self;
        }
        foreach(@handlers) {
            if($_->{name} eq $source) {
                $self->{handler}=$_;
                $self->{valid}=1;
                return $self;
            }
        }
        return $self;
}

sub _cached_load {
    my($self,$source,$what) = @_;
    return unless(defined $CACHED{$source});
    return unless(defined $CACHED{$source}{$what});
    #print STDERR "MyPlace::Archive::LoadFromCache:$source -> $what\n";
    $self->{$what} = $CACHED{$source}{$what} ?  $CACHED{$source}{$what} : undef;
    return 1;
}

sub _cached_save {
    my($self,$source,@what) = @_;
    #print STDERR "MyPlace::Archive::SaveToCache:$source -> ";
    foreach(@what) {
        #print STDERR "$_\t ";
        $CACHED{$source}{$_} = $self->{$_} ? $self->{$_} : 0;
    }
    #print STDERR "\n";
    return $self;
}



sub test {
    my ($self,$source)=@_;
    shift;shift;
    return $self->{filetest} if($self->_cached_load($source,"filetest"));
    return undef unless($self->{handler});
    $self->{filetest} = $self->handler_test($self->{handler},$source,undef);
    $self->_cached_save($source,"filetest");
    return $self->{filetest};
}

sub extract {
    my ($self,$source)=@_;shift;shift;
	print STDERR "Extracting $source @_\n" if($DEBUG);
    $self->_cached_load($source,"handler");
    return undef unless($self->{handler});
    return $self->handler_extract($self->{handler},$source,@_);
}

sub list {
    my $self=shift;
    my $source=shift;
    return @{$self->{filelist}} if($self->_cached_load($source,"filelist"));
    $self->_cached_load($source,"handler");
    return undef unless($self->{handler});
    $self->{filelist} = [$self->handler_list($self->{handler},$source,@_)];
    $self->_cached_save("source","filelist");
    return @{$self->{filelist}};
}

sub _build_handlers {
    foreach(@filetype) {
        my $class = $PACKAGE_NAME . "::" . ucfirst($_);
#        print STDERR "Build handler $class\n";
        eval "use $class";
        next if(@!);
        push @handlers,$class->new();
    }
#    use Data::Dumper;print STDERR Dumper(\@handlers),"\n";
    return \@handlers;
}

sub build_cmdline {
    my ($cmd_a,$source,$entry)=@_;
    $entry="" unless($entry);
    my @cmdline = @{$cmd_a};
    if(grep /^_(:?ARCHIVE|ENTRY)$/,@cmdline) {
        map {$_ eq "_ARCHIVE" ? $_ = "$source" : $_ eq "_ENTRY" ? $_ = "$entry" : undef } @cmdline;  
    }
    else {
        push @cmdline,$source;
        push @cmdline,$entry if($entry);
    }
    #print STDERR "Execute:",join(" ",@cmdline),"\n";
    #map s/([\(\*])/\\$1/,@cmdline;
    return @cmdline;
}

sub null_stdio {
    my $self=shift;
    open $self->{olderr},">&",\*STDERR unless($self->{olderr});
    open $self->{oldout},">&",\*STDOUT unless($self->{oldout});
    open $self->{null},">/dev/null" unless($self->{null});
    open STDOUT,">&",$self->{null};
    open STDERR,">&",$self->{null};
}

sub restore_stdio {
    my $self = shift;
    open STDERR,">&",$self->{olderr} if($self->{olderr});
    open STDOUT,">&",$self->{oldout} if($self->{oldout});
}


sub handler_test {
    my($self,$handler,$source,$level)=@_;
	if($DEBUG) {
		print STDERR "Test archive [level:",$level ? $level :"all","]: ";
	    print STDERR "is \"" . $handler->{name} . "\" format? ";
	}
    my $result;
    $self->null_stdio;

	if(((!$level) or $level==1) and $handler->{file_ext}) {
		foreach(@{$handler->{file_ext}}) {
			if($source =~ $_) {
				$result=1;
				$level=-1;
			}
		}
	}

	if(((!$level) or $level==2) and $handler->{signature}) {
		my @signature = @{$handler->{signature}};
		my $offset = shift @signature;
		my $sign = join("",map chr,@signature);
		$result = undef;
		if(open FI,"<:raw",$source) {
			my $test_code;
			sysread FI,$test_code,length($sign),$offset;
			close FI;
			if($test_code eq $sign) {
				$result=1;
				$level=-1;
			}
		}
	}

	if($level>=3 and $handler->{cmd_test}) {
        unless(system(build_cmdline($handler->{cmd_test},$source))) {
			$result=1;
			$level=-1;
		}
    }
	
	if($level>=4 and $handler->can("can_handler")) {
        $result = $handler->can_handler($source);
		$level = -1;
    }
    $self->restore_stdio;

    print STDERR $result ? "yes" : "no","\n" if($DEBUG);
    return $result;
}
sub handler_extract {
    my($self,$handler,$source,$entry)=@_;
#    print STDERR "Extract $entry from $source\n";
    my $result;
    $self->null_stdio;
    if($handler->{cmd_extract}) {
        open FI,"-|:raw",build_cmdline($handler->{cmd_extract},$source,$entry) or return undef;
        $result=join("",<FI>);
        close FI;
    }
    else {
        $result=$handler->get_entry($source,$entry);
    }
    $self->restore_stdio;
    return $result;
}
sub handler_list {
    my($self,$handler,$source,$entry)=@_;
    my @result;
    if($handler->{cmd_list}) {
        open FI,"-|",build_cmdline($handler->{cmd_list},$source) or return undef;
        @result=<FI>;
		close FI;
    }
    else {
        @result=$handler->list_content($source);
    }
    my %t_dirs;
    my @t_files;
    foreach(@result) {
        chomp;
        s/\\/\//g;
        if(/\/$/) {
            $t_dirs{$_}=1;
        } 
        else {
            if(/^(.*\/)/) {
                $t_dirs{$1}=1;
            }
            push @t_files, $_;
        }
    }
    my @dirs = keys %t_dirs;
    my @files = ();
    foreach(@t_files) {
        push @files,$_ unless($t_dirs{$_ . "\/"});
    }
    return \@dirs,\@files;
}

1;
