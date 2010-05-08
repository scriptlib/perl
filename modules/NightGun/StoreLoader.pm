#!/usr/bin/perl -w
package NightGun::StoreLoader;
use strict;
use warnings;
use NightGun;
use NightGun::Store::Base;
#use NightGun::Store::Archive;
use NightGun::Store::Zbook;
my  @filetype = ("Zbook","Archive");

sub new {
	my ($class, $parent) = @_;
	my $self = bless {},$class;
	return $self;
}

sub load {
    my ($self,$path) = @_;
    my $store;
	NightGun::message("StoreLoader","Loading $path");
    foreach my $type (@filetype) {
        $store = undef;
        my $class = _load_filetype($type);
        if($class) {
            NightGun::message("StoreLoader","Trying " . $class,"...");
            $store = $class->new();
            if($store->load($path)) {
                NightGun::message("StoreLoader:","$class [OK]");
                last;
            }
            NightGun::warn("StoreLoader","$class [Failed]");
            $store = undef;
        }
    }
    unless($store) {
        $store = NightGun::Store::Base->new($path);
        $store->load($path);
    }
    NightGun::message("StoreLoader","Get ",scalar(@{$store->{files}})," files, ",scalar(@{$store->{directories}})," directories");
    return $store;
}

sub _load_filetype {
    my $class = shift;
    $class = "NightGun::Store::$class";
#    return $class if(defined $class);
#    warn "Eval Loading $class ...";
    eval "use $class";
    return undef if(@!);
    return $class;
}
