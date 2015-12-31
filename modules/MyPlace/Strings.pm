#!/usr/bin/perl -w
package MyPlace::Strings;
use strict;
use warnings;
BEGIN {
    require Exporter;
    our ($VERSION,@ISA,@EXPORT,@EXPORT_OK,%EXPORT_TAGS);
    $VERSION        = 1.00;
    @ISA            = qw(Exporter);
    @EXPORT         = qw(rotate13);
    @EXPORT_OK      = qw(c change rotate13);
}
sub new {my $class = shift;return bless {@_},$class;}

my @methods = qw/
    rmask
    rotate13
/;

sub rmask {
    my @result = @_;
    foreach(@result) {
         tr/abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ#@?!./nopqrstuvwxyzabcdefghijklmNOPQRSTUVWXYZABCDEFGHIJKLM.!?@#/;
    }
    return @result;
}
sub rotate13 {
    my @result = @_;
    foreach(@result) {
         tr/abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ/nopqrstuvwxyzabcdefghijklmNOPQRSTUVWXYZABCDEFGHIJKLM/;
    }
    return @result;
}

sub c {
    goto &change;
}

sub change {
    my $self = shift;
    unless(ref $self) {
        unshift @_,$self;
    }
    my ($method_exp,@text) = @_;
    my @result;
    foreach(@methods) {
        if(m/$method_exp/) {
            @result = eval($_ . '(@text);');
            last;
        }
    }
    return @result;
}

1;

__END__
=pod

=head1  NAME

MyPlace::Strings - PERL Module

=head1  SYNOPSIS

use MyPlace::Strings;

=head1  DESCRIPTION

___DESC___

=head1  CHANGELOG

    2010-11-09 23:30  xiaoranzzz  <xiaoranzzz@myplace.hell>
        
        * file created.

=head1  AUTHOR

xiaoranzzz <xiaoranzzz@myplace.hell>


# vim:filetype=perl
