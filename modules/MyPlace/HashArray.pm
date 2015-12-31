#!/usr/bin/perl -w
package MyPlace::HashArray;
use strict;
use warnings;
BEGIN {
    require Exporter;
    our ($VERSION,@ISA,@EXPORT,@EXPORT_OK,%EXPORT_TAGS);
    $VERSION        = 1.00;
    @ISA            = qw(Exporter);
    @EXPORT         = qw();
    @EXPORT_OK      = qw();
}

sub error {
	my $self = shift;
	$self->{last_error} = [@_];
	return undef,@_;
}

sub new {my $class = shift;return bless {@_},$class;}

sub write {
	my $self = shift;
	$self = new MyPlace::HashArray unless(ref $self);
	my $database = shift(@_) || $self->{database};
	return $self->error('No database to write!') unless($database);
	$self->{database} = $database;
	open FO,">",$database or return $self->error("writting $database: $!");
	if($self->{value} and ref $self->{value}) {
		foreach my $name (keys %{$self->{value}}) {
			print FO join("\t",($name,@{$self->{value}})),"\n";
		}
	}
	close FO;
}


sub read {
	my $self = shift;
	$self = new MyPlace::HashArray unless(ref $self);
	my $database = shift || $self->{database};
	return $self->error('No database to read!') unless($database);
	$self->{database} = $database;
	open FI,"<",$database or return $self->error("opening $database: $!");
	foreach(<FI>) {
		chomp;
		s/\s+$//;
		next unless($_);
		my ($name,@names) = split("\t",$_);
		$self->{value}->{$name} = [@names];
	}
	close FI;
	return $self->{value};
}

1;

__END__
=pod

=head1  NAME

MyPlace::HashArray - PERL Module

=head1  SYNOPSIS

use MyPlace::HashArray;

=head1  DESCRIPTION

___DESC___

=head1  CHANGELOG

    2012-01-01 22:19  afun  <afun@myplace.hell>
        
        * file created.

=head1  AUTHOR

afun <afun@myplace.hell>


# vim:filetype=perl

