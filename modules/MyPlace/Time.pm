#!/usr/bin/perl -w
package MyPlace::Time;
use strict;
use warnings;
BEGIN {
    require Exporter;
    our ($VERSION,@ISA,@EXPORT,@EXPORT_OK,%EXPORT_TAGS);
    $VERSION        = 1.00;
    @ISA            = qw(Exporter);
    @EXPORT         = qw();
    @EXPORT_OK      = qw(&now);
}

use POSIX qw/strftime/;

sub new {my $class = shift;return bless {@_},$class;}

sub now {
	my $fmt = shift;
	my @data = @_;
	$fmt = "%Y-%m-%d %H:%M:%S" unless($fmt);
	@data = localtime unless(@data);
	return strftime $fmt,@data;
}


1;

__END__
=pod

=head1  NAME

MyPlace::Time - PERL Module

=head1  SYNOPSIS

use MyPlace::Time;

=head1  DESCRIPTION

___DESC___

=head1  CHANGELOG

    2012-04-13 23:35  xiaoranzzz  <xiaoranzzz@myplace.hell>
        
        * file created.

=head1  AUTHOR

xiaoranzzz <xiaoranzzz@myplace.hell>


# vim:filetype=perl
