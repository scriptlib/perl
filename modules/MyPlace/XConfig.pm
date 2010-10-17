#!/usr/bin/perl -w
package MyPlace::XConfig;
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
my $DEFAULT_CONFIG_FILE='.XCONFIG.PL';
my $PLAIN_LEVEL_MARK_EXP="(?:\t|    )";
my $PLAIN_LEVEL_MARK="    ";

my $SEPARATOR=',';
my $ESCAPE_MARK="\\\\";
my $ESCAPE_MARK_ESCAPE="\0ESCAPE_MARK\0";
my $SEPARATOR_ESCAPE="\0SEPARATOR\0";
my $DIRTY=0;

sub list {
    my ($self,@target) = @_;
    my @r;
    foreach(@target) {
        my ($path,$data,$key) = @{$_};
        $path = join(" -> ",@{$path});
        push @r,$path;
    }
    return @r;
}
sub read {
    my ($self,@target) = @_;
    my @r;
    foreach(@target) {
        my ($path,$data,$key) = @{$_};
        if($data->{$key}) {
            push @r,[$path,[keys %{$data->{$key}}]];
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
    else {
        push @r,[$root];
    }
    return @r;
}

sub get_records {
    my ($self,@target) = @_;
    my $root = $self->{data};
    my @records;
#    use Data::Dumper;print Dumper(\@target);
    foreach(@target) {
        my ($path,$entry,$key) = @{$_};
        my @subpath = _deep_search($entry->{$key});
        if(@subpath) {
            foreach(@subpath) {
                push @records,[@{$path},@{$_}];
            }
        }
        else {
            push @records,$path;
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
sub delete {
    my ($self,$userdata,@target) = @_;
    my $status;
    if($userdata) {
        foreach(@target) {
            if(defined $_->[1]->{$_->[2]}->{$userdata}) {
                delete $_->[1]->{$_->[2]}->{$userdata};
                $self->{dirty}=1;
                $status=1;
            }
        }
    }
    else {
        foreach(@target) {
            if(defined $_->[1]->{$_->[2]}) {
                delete $_->[1]->{$_->[2]};
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
    foreach(@target) {
        $_->[1]->{$_->[2]} = {$userdata=>{}};
        $self->{dirty}=1;
        $status = 1;
    }
    return $status;
}

sub _get_query {
    my $query=shift;
    return unless $query;
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
    my ($self,$path,$data,@query)=@_;
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
                        my @r = $self->_make_query([@{$path},$key],$data->{$key},@query);
                        push @results,@r if(@r);
                    }
                    else {
                        push @results,[[@{$path},$key],$data,$key];
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
                        my @r = $self->_make_query( [@{$path},$key],$data->{$key},@query);
                        push @results,@r if(@r);
                    }
                    else {
                        push @results,[ [@{$path},$key],$data,$key];
                    }
                    last;
                }
            }
            if(!$match) {
                if(@query) {
                    $data->{$exp} = {};
                    $self->{dirty} = 1;
                    my @r = $self->_make_query([@{$path},$exp],$data->{$exp},@query);
                    push @results,@r if(@r);
                }
                else {
                    #push @results,[[@{$path},$exp],$data,$exp];
                }
            }
        }
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

use MIME::Base64;

sub read_plainfile {
    my($self,$file)=@_;
    unless(-r $file) {
        $self->{data} = {};
        return $self->{data};
    }
    my @text;
    if(!open(FH, $file)) {
        print STDERR "$!\n";
        $self->{data}= {};
        return $self->{data};
    }
    else {
        while(<FH>) {
            chomp;
            push @text,$_;
        }
#        @text = <FH>;
        close FH;
    }
    if(@text) {
        if($text[0] =~ '^XConfig') {
            $self->{base64} = 1;
            shift @text;
            @text = map {decode_base64($_);} @text;
        }
        $self->{data} = text_to_hash(0,$PLAIN_LEVEL_MARK_EXP,\@text);
    }
    else {
        $self->{data} = {};
    }
    return $self->{data};
}
sub write_plainfile {
    my($self,$file,$really_plain)=@_;
    my $fh;
    if($file eq '-') {
        $fh = *STDOUT;
    }
    else{
        if(!open $fh,">",$file) {
            print STDERR "$!\n";
            return undef;
        }
    }
        if($really_plain) {
            foreach(hash_to_text(0,$PLAIN_LEVEL_MARK,$self->{data})) {
                print $fh $_,"\n";
            }
        }
        else {
            print $fh "XConfig\n";
            foreach(hash_to_text(0,$PLAIN_LEVEL_MARK,$self->{data})) {
                print $fh encode_base64("$_\n");
            }
        }
        close $fh unless($file eq '-');
        return 1;
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
    my($self,$text) = @_;
    my @querys = _get_query($text);
    return $self->_make_query([],$self->{data},@querys);
}

1;
