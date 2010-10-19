#!/usr/bin/perl -w
package MyPlace::HTTPGet;
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

use LWP::UserAgent;
use HTTP::Cookies;

my $PROXY = '127.0.0.1:9050';
my $BLOCKED_HOST = 'wretch\.cc|facebook\.com|fbcdn\.net';
my $BLOCKED_EXP = qr/^[^\/]+:\/\/[^\/]*(?:$BLOCKED_HOST)(?:\/?|\/.*)$/;
sub new {
    my $class=shift;
    my  $ua = LWP::UserAgent->new;
    $ua->agent("Mozilla/5.0 (X11; U; Linux i686; en-US; rv:1.9.0.3) Gecko/2008092416 Firefox/3.0.3 Firefox/3.0.1");
    return bless {"ua"=>$ua},$class;
}

sub cookie_set {
    my $self = shift;
    my %ck = @_;
    if(!$self->{cookie}) {
        $self->{cookie} = HTTP::Cookies->new(file => "$ENV{'HOME'}/.lwp_cookies.dat", autosave => 1);
        $self->{ua}->cookie_jar($self->{cookie});
    }
    $self->{cookie}->set_cookie(
        $ck{version} || undef,
        $ck{key},$ck{val},
        $ck{path},$ck{domain},
        $ck{port} || undef,
        $ck{path_spec} || "",
        $ck{secure} || undef,
        $ck{maxage} || 3600*24*30,
        $ck{discard} || undef,
    );
    return $self;
}

sub cookie_clear {
    my $self = shift;
    $self->{cookie}->clear;
    return $self;
}

sub request {
    my $self = shift;
    my $req = HTTP::Request->new(@_);
    return $self->{ua}->request($req);
}

sub get {
    my $self = shift;
    my @args;
    my $charset;
    foreach(@_) {
        next unless($_);
        if(m/^charset:([^\s]+)/) {
            $charset = $1;
        }
        else {
            push @args,$_;
        }
    }
    my $req = HTTP::Request->new(GET => @args);
    my $res = $self->{ua}->request($req);
    my $data = $res->content;
    if ($res->is_success) {
        if($charset) {
            require Encode;
            Encode::from_to($data,$charset,'utf8');
        }
        return $res->code,$data;
    }
    else {
        return $res->code,$res->status_line;
        
    }
}

sub get1 {
    my (undef,$content) = &get(@_);
    return $content;
}

sub print {
    my (undef,$content) = &get(@_);
    print STDOUT $content;
}
1;
