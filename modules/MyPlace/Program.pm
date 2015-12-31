#!/usr/bin/perl -w
package MyPlace::Program;
use strict;
use warnings;
BEGIN {
    require Exporter;
    our ($VERSION,@ISA,@EXPORT,@EXPORT_OK,%EXPORT_TAGS);
    $VERSION        = 1.00;
    @ISA            = qw(Exporter);
    @EXPORT         = qw();
    @EXPORT_OK      = qw(\%EXIT_CODE &EXIT_CODE);
}
use Getopt::Long qw/GetOptionsFromArray/;
Getopt::Long::Configure ("bundling", "no_ignore_case");

our %EXIT_CODE = (
	OK=>0,
	ERROR=>1,
	KILLED=>2,
	FAILED=>11,
	IGNORED=>12,
	UNKNOWN=>19,
	USAGE=>3,
	DEBUG=>20,
);

sub EXIT_CODE {
	my $code = shift;
	if(ref $code) {
		$code = shift;
	}
	return $code ? defined $EXIT_CODE{$code} ? $EXIT_CODE{$code} : $code : $EXIT_CODE{UNKNOWN};
}

my $DEF_OPTIONS = [qw/
	help|h|? 
	manual|man
	/];
sub new {
	my $class = shift;
	my $self = bless {},$class;
	my @DEF_OPTIONS = $self->OPTIONS;
	$self->{DEF_OPTIONS} = \@DEF_OPTIONS if(@DEF_OPTIONS);
	my $opt = shift;
	if($opt and ref $opt) {
		$self->{options} = $opt;
	}
	elsif($opt) {
		unshift @_,$opt;
	}
	$self->{ARGV} = [@_] if(@_);
	return $self;
}

sub cathash {
	my $lef = shift;
	my $rig = shift;
	return $lef unless($rig);
	return $lef unless(%$rig);
	my %res = $lef ? %$lef : ();
	foreach(keys %$rig) {
		$res{$_} = $rig->{$_} if(defined $rig->{$_});
	}
	return \%res;
}

sub set {
	my $self = shift;
	my %OPT;
	if(@_) {
		GetOptionsFromArray(\@_,\%OPT,@{$self->{DEF_OPTIONS}});
	}
	else {
		$OPT{'help'} = 1;
	}
	$self->{options} = cathash($self->{options},\%OPT);
	push @{$self->{ARGV}},@_ if(@_);
}

sub OPTIONS {
	return @$DEF_OPTIONS;
}

sub USAGE {
	my $self = shift;
	require Pod::Usage;
	Pod::Usage::pod2usage(@_);
	return 0;
}

sub MAIN {
	print STDERR "sub MAIN not implemented\n";
	return 1;
}

sub execute {
	my $self = shift;
	my $OPT;
	if(@_) {
		$OPT = {ORIGINAL_ARGV=>[@_]};
		GetOptionsFromArray(\@_,$OPT,@{$self->{DEF_OPTIONS}});
		$OPT = cathash($self->{options},$OPT);
	}
	else {
		$OPT = $self->{options};
		@_ = @{$self->{ARGV}} if($self->{ARGV} && @{$self->{ARGV}});
	}
	if((!@_) && $self->{NEEDARGV}) {
		$OPT->{help} = 1;
	}
	if($OPT->{help}) {
		return $self->USAGE('-exitval'=>1,'-verbose'=>1);
	}
	elsif($OPT->{manual}) {
		return $self->USAGE('--exitval'=>1,'-verbose'=>2);
	}
	$self->{ARGV} = [];
	return $self->MAIN($OPT,@_);
}

sub run {
	my $class = shift;
	my $self = new($class);
	return $self->execute(@_);
}

my $MSG_PROMPT = '';

sub init_print {
	my $self = shift;
	$self->{MSG_PROMPT} = join(" ",@_);
}

sub print_msg {
	my $self = shift;
	my $MSG_PROMPT = $self->{MSG_PROMPT} || '';
	print STDERR "$MSG_PROMPT> ",@_;
}

sub print_err {
	my $self = shift;
	my $MSG_PROMPT = $self->{MSG_PROMPT} || '';
	print STDERR "$MSG_PROMPT> ",@_;
}

sub print_warn {
	my $self = shift;
	my $MSG_PROMPT = $self->{MSG_PROMPT} || '';
	print STDERR "$MSG_PROMPT> ",@_;
}

1;
__END__
