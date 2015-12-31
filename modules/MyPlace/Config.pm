#!/usr/bin/perl -w
package MyPlace::Config;
use strict;
use warnings;
BEGIN {
#    sub debug_print {
#        return unless($ENV{XR_PERL_MODULE_DEBUG});
#        print STDERR __PACKAGE__," : ",@_;
#    }
#    &debug_print("BEGIN\n");
    require Exporter;
    our ($VERSION,@ISA,@EXPORT,@EXPORT_OK,%EXPORT_TAGS);
    $VERSION        = 1.00;
    @ISA            = qw(Exporter);
    @EXPORT         = qw();
    @EXPORT_OK      = qw();
}
my $DEFAULT_CONFIG_FILE='.RCONFIG.PL';
my $PLAIN_LEVEL_MARK_EXP="(?:\t|    )";
my $PLAIN_LEVEL_MARK="    ";

my $SEPARATOR=',';
my $ESCAPE_MARK="\\\\";
my $ESCAPE_MARK_ESCAPE="\0ESCAPE_MARK\0";
my $SEPARATOR_ESCAPE="\0SEPARATOR\0";
my $DIRTY=0;

sub all {
	my $self = shift;
	my %r;
	if($self->{data}) {
		%r = (%{$self->{data}});
	}
	else {
		%r = ();
	}
	return \%r;
}

sub list {
    my ($self,@target) = @_;
    my @r;
    foreach(@target) {
		my @path = @{$_};
        push @r,join(" -> ",@path);
    }
    return @r;
}
sub read {
    my ($self,@target) = @_;
    my @r;
    foreach(@target) {
		my @path = @{$_};
		my $data = $self->{data};
		foreach(@path) {
			if($data->{$_}) {
				$data = $data->{$_}
			}
			else {
				$data = undef;	
				last;
			}
		}
		if($data) {
			push @r,[\@path,[keys %{$data}]];
		}
    }
    return @r;
}
sub array_to_hash {
	my $self = shift;
	my $array = shift;
	return undef unless($array);
	return undef unless(@{$array});
	my %hash;
	foreach(@{$array}) {
		$hash{$_} = {};
	}
	return \%hash;
}
sub get {
	my $self = shift;
	my @r;
	foreach my $path (@_) {
		my ($data) = $self->lookup_to($path);
		if($data) {
			push @r,[$path,keys %{$data}];
		}
		else {
			push @r,[$path,undef];
		}
	}
	return @r;
}
sub set {
	my $self = shift;
	my $value = shift;
	if(ref $value) {
		$value = $self->array_to_hash($value);
	}
	else {
		$value = $self->array_to_hash([$value]);
	}
	my @r;
	foreach my $path (@_) {
		my ($data,$pdata,$key) = $self->lookup_to($path,1);
		if($pdata and $key) {
			$pdata->{$key} = $value;
			$self->{dirty} = 1;
			push @r,$data;
		}
	}
	return @r;
}

sub add {
    my($self,@keys) = @_;
    my $p=$self->{data};
    foreach(@keys) {
        $p ->{$_} = {} unless($p->{$_});
        $p = $p->{$_};
    }
#    $p->{$value}={};
    $self->{dirty}=1;
    return $p;
}

sub _deep_search {
    my $root = shift;
    my @r;
    if($root and %{$root}) {
        foreach my $key (keys %{$root}) {
            if($root->{$key} and %{$root->{$key}}) {
                foreach my $d (_deep_search($root->{$key})) {
                    push @r,[$key,@{$d}];
                }
            }
            else {
                push @r,[$key];
            }
        }
    }
#    else {
#        push @r,[$root];
#    }
    return @r;
}

sub get_records {
    my ($self,@target) = @_;
    my $root = $self->{data};
    my @records;
#    use Data::Dumper;print Dumper(\@target);
    foreach(@target) {
		my @path = @{$_};
		my $entry = $self->{data};
		my $match = 0;
		foreach(@path) {
			if(!$entry->{$_}) {
				$match = 0;
				last;
			}
			else {
				$entry = $entry->{$_};
			}
			$match = 1;
		}
		if($match) {
			my @r = _deep_search($entry);
			if(@r) {
				foreach(_deep_search($entry)) {
					push @records, [@path,@{$_}];
				}
			}
			else {
				push @records,\@path;
			}
		}
		else {
			push @records,\@path;
		}
    }
    return @records;
}
sub propget {
    my($self,@keys) = @_;
    my $r=$self->{data};
    foreach(@keys) {
        next unless($_);
        return unless($r->{$_});
        $r = $r->{$_};
    }
    return unless($r and %{$r});
    return keys %{$r};
}
sub propset {
    my($self,$value,@keys) = @_;
    my $p=$self->{data};
    my $r;
    my $last;
    my $key = pop @keys;
    foreach(@keys) {
        $last=$_;
        $p ->{$_} = {} unless($p->{$_});
        $r = $p;
        $p = $p->{$_};
    }
    return unless($r);
    #${$r} = {$last=>{$value=>{}}};
    $r->{$last} = {$key=>{$value=>{}}};
    $self->{dirty}=1;
    return $p;
}

sub lookup_to {
	my $self = shift;
	my $path = shift;
	my $auto_create = shift;
	return undef unless($path and ref $path);
	my $data = $self->{data};
	my $pdata = undef;
	my $lastkey = undef;
	my $found = 0;
	foreach(@{$path}) {
		if($data->{$_}) {
			$pdata = $data;
			$lastkey = $_;
			$data = $data->{$_};
		}
		elsif($auto_create) {
			$data->{$_} = {};
			$pdata = $data;
			$lastkey = $_;
			$data = $data->{$_};
		}
		else {
			$found = 0;
			last;
		}
		$found = 1;
	}
	if($found) {
		return $data,$pdata,$lastkey;
	}
	else {
		return undef;
	}
}

sub delete {
    my ($self,$userdata,@target) = @_;
    my $status;
    if($userdata) {
        foreach my $path (@target) {
			my ($data,$pdata,$lastkey) = $self->lookup_to($path);
			if($data) {
				delete $data->{$userdata};
                $self->{dirty}=1;
                $status=1;
			}
        }
    }
    else {
        foreach my $path (@target) {
			my ($data,$pdata,$lastkey) = $self->lookup_to($path);
			if($pdata) {
				delete $pdata->{$lastkey};
                $self->{dirty}=1;
                $status=1;
            }
        }
    }
    return $status;
}
sub write {
    my ($self,$userdata,@target) = @_;
    return unless($userdata);
    my $status;
#	use Data::Dumper;print Data::Dumper->Dump([$self->{data}],['*data']);
    foreach(@target) {
		my @path = @{$_};
		my $data = \%{$self->{data}};
		foreach(@path) {
			if(!$data->{$_}) {
				$data->{$_} = {};
			}
			$data = \%{$data->{$_}};
		}
		$data->{$userdata} = {};
        $self->{dirty}=1;
        $status = 1;
    }
#	use Data::Dumper;print Data::Dumper->Dump([$self->{data}],['*data']);
    return $status;
}

sub _get_query {
    my $query=shift;
    return unless $query;
	if(ref $query) {
		my @queries;
		foreach(@{$query}) {
			push @queries,_get_query($_);
		}
		return @queries;
	}
    if($query =~ /^\$/) {
        my $text = '';
        foreach my $idx (1..10) {
            if($query =~ /\$$idx=([^\$]+)/) {
                $text= $text . ',' . $1;
            }
            else {
                $text = $text . ',' . '/.+/';
            }
        }
        $text =~ s/^,+//;
        $text =~ s/(,\/\.\+\/)+$//;
        $query = $text;
#        print STDERR $text;
    }
    $query =~ s/$ESCAPE_MARK$ESCAPE_MARK/$ESCAPE_MARK_ESCAPE/g;
    $query =~ s/$ESCAPE_MARK$SEPARATOR/$SEPARATOR_ESCAPE/g;
    my @querys = split(/\s*$SEPARATOR\s*/,$query);
    foreach(@querys) {
        s/$ESCAPE_MARK_ESCAPE/$ESCAPE_MARK/g;
        s/$SEPARATOR_ESCAPE/$SEPARATOR/g;
    }
    return @querys;
}

sub _make_query {
    my ($self,$path,$data,$auto_create,@query)=@_;
    return unless(defined $data);
    return unless(@query);
#    $path = "$path->" if($path);
    my $data_type = ref $data;
#    print STDERR "$path data is $data_type\n";
    return unless($data_type eq 'HASH');
    my @results;
#    while (@query) {
        my $exp = shift @query;
        if($exp =~ m/^\/(.+)\/$/) {
            $exp = qr/$1/;
            foreach my $key (keys %{$data}) {
                if($key =~ $exp) {
                    if(@query) {
                        my @r = $self->_make_query([@{$path},$key],$data->{$key},$auto_create,@query);
                        push @results,@r if(@r);
                    }
                    else {
                        push @results,[@{$path},$key];
                    }
                }
            }
        }
        else {
            my $match = 0;
            foreach my $key (keys %{$data}) {
                if($key eq $exp) {
                    $match = 1;
                    if(@query) {
                        my @r = $self->_make_query( [@{$path},$key],$data->{$key},$auto_create,@query);
                        push @results,@r if(@r);
                    }
                    else {
                        push @results,[@{$path},$key];
                    }
                    last;
                }
            }
            if(!$match) {
                if(@query) {
                    $data->{$exp} = {};
                    $self->{dirty} = 1;
                    my @r = $self->_make_query([@{$path},$exp],$data->{$exp},$auto_create,@query);
                    push @results,@r if(@r);
                }
                elsif($auto_create) {
                    push @results,[@{$path},$exp];
                }
            }
        }
	#print Data::Dumper->Dump([\@results],['*results']);
    return @results;
}

sub text_to_hash {
    my($level,$level_mark_exp,$text)=@_;
    my %r;
    my $cur;
    my $exp = $level_mark_exp x $level;
    my $next_exp = $level_mark_exp x ($level+1);
    while(@{$text}) {
        my $line = shift @{$text};
        $line =~ s/\s+$//;
        next unless($line);
        if($cur and $line =~ /^$next_exp/) {
            unshift @{$text},$line;
            $r{$cur} = &text_to_hash($level+1,$level_mark_exp,$text);
        }
        elsif($line =~ /^$exp(.+)$/) {
            $cur = $1;
#            print "$level",$cur,"\n";
            $r{$cur} = {};
        }
        else {
            unshift @{$text},$line;
            return \%r;
        }
    }
    return \%r;
}


sub hash_to_text {
    my($level,$level_mark,$hash)=@_;
    my @r;
    return unless ($hash and ref $hash);
    if(%{$hash}) {
        foreach my $key (sort keys %{$hash}) {
            push @r,($level_mark x $level) . $key ;
            my @next = &hash_to_text($level+1,$level_mark,$hash->{$key});
            push @r,@next;
        }
    }
    return @r;
}
sub read_plainfile {
    my($self,$file)=@_;
    unless(-r $file) {
        $self->{data} = {};
        return $self->{data};
    }
    my @text;
    if(!open(FH,"<",$file)) {
        print STDERR "$!\n";
        $self->{data}= {};
        return $self->{data};
    }
    else {
        @text = <FH>;
        close FH;
    }
    if(@text) {
        $self->{data} = text_to_hash(0,$PLAIN_LEVEL_MARK_EXP,\@text);
    }
    else {
        $self->{data} = {};
    }
    return $self->{data};
}
sub write_plainfile {
    my($self,$file)=@_;
    if(!open FO,">",$file) {
        print STDERR "$!\n";
        return undef;
    }
    else {
        foreach(hash_to_text(0,$PLAIN_LEVEL_MARK,$self->{data})) {
            print FO $_,"\n";
        }
        close FO;
        return 1;
    }
}

sub write_file {
    my ($self,$data,$file)=@_;
    use Data::Dumper;
    my $dumper = Data::Dumper->new([$data],[qw/data/]);
    $dumper->Indent(2)->Sortkeys(1);
    #->Purity(1);
    if(!open FO,">",$file) {
        print STDERR "$!\n";
        return undef;
    }
    else {
        print FO $dumper->Dump();
        return 1;
    }
}
sub read_file {
    my $self = shift;
    my $file = shift;
    unless(-f $file and -r $file) {
        $self->{data} = {};
        return $self->{data};
    }
    my $text;
    {
        local( $/, *FH ) ;
        if(!open( FH, $file )) {
            print STDERR "$!\n";
            $self->{data}= {};
            return $self->{data};
        }
        $text = <FH>;
        close FH;
    }
    return $self->read_string($text);
}

sub new {
    my $class = shift;
    my $self =  bless {@_},$class;
    $self->{database} = $DEFAULT_CONFIG_FILE unless($self->{database});
    return $self;
}

sub load {
    my($self,$database) = @_;
    $self->{database} = $database if($database);
    $self->read_file($self->{database});
    return $self;
}

sub read_string {
    my($self,$text) = @_;
    my $data;
    eval($text);
    if($!) {
        print STDERR "$!\n";
    }
    $self->{data} = $data ? $data : {};
    return $self->{data};
}

sub save {
    my($self,$database) = @_;
    $self->{database} = $database if($database);
    $self->write_file($self->{data},$self->{database});
    return $self;
}

sub query {
    my($self,$text,$auto_create) = @_;
    my @querys = _get_query($text);
    return $self->_make_query([],$self->{data},$auto_create,@querys);
}

1;
