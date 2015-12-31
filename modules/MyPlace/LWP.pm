#!/usr/bin/perl -w
package MyPlace::LWP;
use strict;
use warnings;
use feature qw/state/;
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
use HTTP::Cookies::Microsoft;

my $PROXY = '127.0.0.1:9050';
my $BLOCKED_HOST = 'wretch\.cc|facebook\.com|fbcdn\.net';
my $BLOCKED_EXP = qr/^[^\/]+:\/\/[^\/]*(?:$BLOCKED_HOST)(?:\/?|\/.*)$/;
sub new {
    my $class=shift;
    my  $ua = LWP::UserAgent->new;
    $ua->agent("Mozilla/5.0 (X11; U; Linux i686; en-US; rv:1.9.0.3) Gecko/2008092416 Firefox/3.0.3 Firefox/3.0.1");
    my $self = bless {"UserAgent"=>$ua,"progress"=>1,@_},$class;
	$self->{cookie} = HTTP::Cookies::Netscape->new(file => "$ENV{'HOME'}/.lwp_cookies.dat", delayload=>1,autosave => 1);
    $self->{UserAgent}->cookie_jar($self->{cookie});
	return $self;
}

sub cookie_set {
    my $self = shift;
    my %ck = @_;
    #$self->{UserAgent}->cookie_jar($self->{cookie});
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
    return $self->{UserAgent}->request($req);
}

sub request_init {
	my $self = shift;
	$self->{bytes_received} = 0;
	delete $self->{expected_length};
	$self->{chunks} = "";
	return $self;
}

sub chunk_income {
	my $self = shift;
	my ($chunk,$res) = @_;
	$self->{chunks} .= $chunk;
	if($self->{callback_progress}) {
		return &$self->{callback_progress}(@_);
	}
	my $first_chunk = ($self->{bytes_received} eq '0');
	if($self->{progress}) {
		my $length = length($chunk);
		$self->{bytes_received} += $length;
		unless(defined $self->{expected_length}) {
			$self->{expected_length} = $res->content_length || 0;
		}
		if($self->{expected_length}) {
			print STDERR " "x7 if($first_chunk);
			printf STDERR "\b"x7 . "[%3d%%] ",100 * $self->{bytes_received} / $self->{expected_length};
		}
		else {
			state $nKB = 0;
			state $count = 0;
			if($first_chunk) {
				$nKB = 0;
				$count = 0;
				print STDERR " ";
			}
			if(($nKB + $length) < 1024*10) {
				$nKB += $length;
			}
			else {	
				$nKB = 0;
				$count = 0 if($count>2);
				$count ++;
				print STDERR "\b" . ($count eq '0' ? '/' : $count eq '1' ? '-' : '\\') ;
			}
		}
	}
#	$first_chunk = 0;
	return $self;
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
	$self->request_init;
#    my $req = HTTP::Request->new(GET => @args);
    my $res = $self->{UserAgent}->get(@args,':content_cb'=> sub {$self->chunk_income(@_);});
	print STDERR "\b." if($self->{progress});
    my $data = $self->{chunks};
    if ($res->is_success) {
        if($charset) {
            require Encode;
			my $dec = Encode::find_encoding($charset);
			if($dec && ref $dec) {
				$data = $dec->decode($data);
			}
        }
		if(wantarray) {
	        return 1,$data,$res;#res,$data;
		}
		else {
			return $data;
		}
    }
    elsif(wantarray) {
        return undef,undef,$res;
	}
	else {
		return undef;
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

__END__
=pod

=head1  NAME

MyPlace::LWP - PERL Module

=head1  SYNOPSIS

use MyPlace::LWP;

=head1  DESCRIPTION

___DESC___

=head1  CHANGELOG

    2012-01-17 22:49  xiaoranzzz  <xiaoranzzz@myplace.hell>
        
        * file created.

=head1  AUTHOR

xiaoranzzz <xiaoranzzz@myplace.hell>


# vim:filetype=perl

