#!/usr/bin/perl -w
package MyPlace::Curl;
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
my @CURL = qw{
            curl
            --fail
            --globoff
            --location
            --user-agent Mozilla/5.0
            --progress-bar
            --create-dirs
            --connect-timeout 15
};

sub new {
    my $class = shift;
    my $self = bless {},$class;
    $self->{options} = {@_};
    return $self;
}
sub set {
    my $self = shift;
    my $name = shift;
    my $value = shift;
    $self->{options}->{$name} = $value;
}

sub _build_cmd 
{
    my $self = shift;
    my @cmds;
#    my @cmds = @CURL;
    foreach(keys %{$self->{options}})
    {
        if($self->{options}->{$_}) 
        {
            push @cmds,"--$_",$self->{options}->{$_};
        }
        else
        {
            push @cmds,"--$_";
        }
    }
    return @cmds;
}

sub _run_curl 
{
    my $self = shift;
    my @data;
    my @cmds = (@CURL,$self->_build_cmd);
    push @cmds,@_ if(@_);
#    print STDERR join(" ",@cmds),"\n";
    open FI,"-|",@cmds;
    @data=<FI>;
    close FI;
    return $?,@data;
}

sub get {
    my $self = shift;
    my $url = shift;
    return $self->_run_curl(@_,"--url",$url);
}
sub post {
    my $self = shift;
    my $url = shift;
    my $referer = shift;
    my %posts = @_;
    return undef unless($url);


    my @args = ("--url",$url);
    push @args,"--referer",$referer if($referer);
    if(%posts) 
    {
        foreach (keys %posts) 
        {
            push @args,"--data-urlencode","$_=$posts{$_}";
        }
    }
    return $self->_run_curl(@args);
}

sub print {
    my $self = shift;
    my $action = shift;
    if($action eq 'post') {
        print $self->post(@_);
    }
    else {
        print $self->get(@_);
    }
}

1;
